// Copyright 2023 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org
package skip.model

import android.os.Looper
import kotlinx.coroutines.DelicateCoroutinesApi
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import skip.foundation.DispatchQueue
import skip.foundation.RunLoop
import skip.foundation.Scheduler
import skip.lib.Long
import skip.lib.Never
import java.lang.ref.WeakReference
import java.util.LinkedList

interface Publisher<Output, Failure> {
    fun sink(receiveValue: (Output) -> Unit): AnyCancellable

    fun <Root> assign(to: (Root, Output) -> Unit, on: Root): AnyCancellable {
        return sink { it -> to(on, it) }
    }

    fun debounce(for_: Double, scheduler: Scheduler): Publisher<Output, Failure> {
        return Debounce(this, seconds = for_, scheduler)
    }

    fun dropFirst(count: Int = 1): Publisher<Output, Failure> {
        return DropFirst(this, count)
    }

    fun filter(isIncluded: (Output) -> Boolean): Publisher<Output, Failure> {
        return Filter(this, isIncluded)
    }

    fun <T> map(transform: (Output) -> T): Publisher<T, Failure> {
        return Map(this, transform)
    }

    fun receive(on: Scheduler): Publisher<Output, Failure> {
        return ReceiveOn(this, on)
    }
}

interface Subject<Output, Failure> : Publisher<Output, Failure> {
    fun send(value: Output)
}

class PassthroughSubject<Output, Failure> : Subject<Output, Failure> {
    private val helper = SubjectHelper<Output, Failure>()

    override fun sink(receiveValue: (Output) -> Unit): AnyCancellable = helper.sink(receiveValue)

    override fun send(value: Output) = helper.send(value)
}

class ObservableObjectPublisher : Publisher<Unit, Never> {
    private val helper = SubjectHelper<Unit, Never>()

    override fun sink(receiveValue: (Unit) -> Unit): AnyCancellable = helper.sink(receiveValue)

    fun send() = helper.send(Unit)
}

/// Helper to implement subjects and publishers.
internal class SubjectHelper<Output, Failure> {
    // Keep sinks in order
    private var sinks: LinkedList<WeakReference<AnyCancellable>>? = null

    fun sink(receiveValue: (Output) -> Unit): AnyCancellable {
        val cancellable = AnyCancellable()
        cancellable.cancellable = Sink(onReceive = receiveValue, onCancel = {
            synchronized(this) {
                val itr = sinks?.listIterator()
                if (itr != null) {
                    while (itr.hasNext()) {
                        val candidate = itr.next().get()
                        if (candidate == null || candidate == cancellable) {
                            itr.remove()
                        }
                    }
                }
            }
        })
        synchronized(this) {
            if (sinks == null) {
                sinks = LinkedList()
            }
            sinks?.add(WeakReference(cancellable))
        }
        return cancellable
    }

    fun send(value: Output) {
        var receivers: MutableList<(Output) -> Unit>? = null
        synchronized(this) {
            val itr = sinks?.listIterator()
            if (itr != null) {
                while (itr.hasNext()) {
                    val sink = itr.next().get()?.cancellable as? Sink<Output>
                    if (sink == null) {
                        itr.remove()
                    } else {
                        if (receivers == null) {
                            receivers = mutableListOf()
                        }
                        receivers!!.add(sink.onReceive)
                    }
                }
            }
        }
        receivers?.forEach { it(value) }
    }

    private class Sink<Output>(val onReceive: (Output) -> Unit, val onCancel: () -> Unit) : Cancellable {
        override fun cancel() {
            onCancel()
        }
    }
}

private class Debounce<Output, Failure>(val publisher: Publisher<Output, Failure>, val seconds: Double, val scheduler: Scheduler) : Publisher<Output, Failure> {
    private var job: Job? = null

    @OptIn(DelicateCoroutinesApi::class)
    override fun sink(receiveValue: (Output) -> Unit): AnyCancellable {
        return publisher.sink { output ->
            job?.cancel()
            job = GlobalScope.launch {
                withContext(Dispatchers.Main) {
                    delay(Long(seconds * 1000))
                    receiveValue(output)
                }
            }
        }
    }
}

private class DropFirst<Output, Failure>(val publisher: Publisher<Output, Failure>, var count: Int) : Publisher<Output, Failure> {
    override fun sink(receiveValue: (Output) -> Unit): AnyCancellable {
        return publisher.sink { output ->
            count--
            if (count < 0) {
                receiveValue(output)
            }
        }
    }
}

private class Filter<Output, Failure>(val publisher: Publisher<Output, Failure>, val isIncluded: (Output) -> Boolean) : Publisher<Output, Failure> {
    override fun sink(receiveValue: (Output) -> Unit): AnyCancellable {
        return publisher.sink { output ->
            if (isIncluded(output)) {
                receiveValue(output)
            }
        }
    }
}

private class Map<T, Output, Failure>(val publisher: Publisher<Output, Failure>, val transform: (Output) -> T) : Publisher<T, Failure> {
    override fun sink(receiveValue: (T) -> Unit): AnyCancellable {
        return publisher.sink { output ->
            receiveValue(transform(output))
        }
    }
}

private class ReceiveOn<Output, Failure>(val publisher: Publisher<Output, Failure>, val scheduler: Scheduler) : Publisher<Output, Failure> {
    @OptIn(DelicateCoroutinesApi::class)
    override fun sink(receiveValue: (Output) -> Unit): AnyCancellable {
        return publisher.sink { output ->
            if ((scheduler == RunLoop.main || scheduler == DispatchQueue.main) && Looper.myLooper() != Looper.getMainLooper()) {
                GlobalScope.launch {
                    withContext(Dispatchers.Main) {
                        receiveValue(output)
                    }
                }
            } else {
                receiveValue(output)
            }
        }
    }
}