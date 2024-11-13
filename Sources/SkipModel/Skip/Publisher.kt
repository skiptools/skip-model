// Copyright 2023 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org
package skip.model

import android.os.Looper
import java.lang.ref.WeakReference
import java.util.LinkedList
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
import skip.lib.Tuple2
import skip.lib.Tuple3
import skip.lib.Tuple4

interface Publisher<Output, Failure> {
    fun sink(receiveValue: (Output) -> Unit): AnyCancellable

    fun <Root> assign(to: (Root, Output) -> Unit, on: Root): AnyCancellable {
        return sink { it -> to(on, it) }
    }

    fun <P> combineLatest(publisher: Publisher<P, Failure>): Publisher<Tuple2<Output, P>, Failure> {
        return CombineLatest(this, with = publisher)
    }

    fun <P0, P1> combineLatest3(publisher0: Publisher<P0, Failure>, publisher1: Publisher<P1, Failure>): Publisher<Tuple3<Output, P0, P1>, Failure> {
        return CombineLatest3(this, with0 = publisher0, with1 = publisher1)
    }

    fun <P0, P1, P2> combineLatest4(publisher0: Publisher<P0, Failure>, publisher1: Publisher<P1, Failure>, publisher2: Publisher<P2, Failure>): Publisher<Tuple4<Output, P0, P1, P2>, Failure> {
        return CombineLatest4(this, with0 = publisher0, with1 = publisher1, with2 = publisher2)
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

    fun eraseToAnyPublisher(): AnyPublisher<Output, Failure> {
        return AnyPublisher(this)
    }
}

interface ConnectablePublisher<Output, Failure> : Publisher<Output, Failure> {
    fun connect(): Cancellable

    fun autoconnect(): Publisher<Output, Failure> {
        return AutoconnectPublisher(this)
    }
}

interface Subject<Output, Failure> : Publisher<Output, Failure> {
    fun send(value: Output)
}

class AnyPublisher<Output, Failure>(private val publisher: Publisher<Output, Failure>) : Publisher<Output, Failure> {
    override fun sink(receiveValue: (Output) -> Unit): AnyCancellable = publisher.sink(receiveValue)

    override fun eraseToAnyPublisher(): AnyPublisher<Output, Failure> = this
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
        val lock = this
        cancellable.cancellable = Sink(onReceive = receiveValue, onCancel = {
            synchronized(lock) {
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
        synchronized(lock) {
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

private class AutoconnectPublisher<Output, Failure>(val publisher: ConnectablePublisher<Output, Failure>): Publisher<Output, Failure> {
    private var connection: Cancellable? = null
    private var subscribers = 0

    override fun sink(receiveValue: (Output) -> Unit): AnyCancellable {
        val lock = this
        synchronized(lock) {
            subscribers++
            if (subscribers == 1) {
                connection = publisher.connect()
            }
        }
        val cancellable = publisher.sink(receiveValue)
        return AnyCancellable {
            cancellable.cancel()
            synchronized(lock) {
                subscribers--
                if (subscribers <= 0) {
                    connection?.cancel()
                    connection = null
                }
            }
        }
    }

    fun finalize() {
        connection?.cancel()
    }
}

private class CombineLatest<P0, P1, Failure>(val publisher: Publisher<P0, Failure>, val with: Publisher<P1, Failure>): Publisher<Tuple2<P0, P1>, Failure> {
    private var publisherLatest: P0? = null
    private var withLatest: P1? = null

    override fun sink(receiveValue: (Tuple2<P0, P1>) -> Unit): AnyCancellable {
        val lock = this
        val publisherCancellable = publisher.sink { latest ->
            val publisherLatest: P0?
            val withLatest: P1?
            synchronized(lock) {
                this.publisherLatest = latest
                publisherLatest = latest
                withLatest = this.withLatest
            }
            sendLatest(receiveValue, publisherLatest, withLatest)
        }
        val withCancellable = with.sink { latest ->
            val publisherLatest: P0?
            val withLatest: P1?
            synchronized(lock) {
                this.withLatest = latest
                publisherLatest = this.publisherLatest
                withLatest = latest
            }
            sendLatest(receiveValue, publisherLatest, withLatest)
        }
        return AnyCancellable {
            publisherCancellable?.cancel()
            withCancellable?.cancel()
        }
    }

    private fun sendLatest(receiveValue: (Tuple2<P0, P1>) -> Unit, publisherLatest: P0?, withLatest: P1?) {
        if (publisherLatest != null && withLatest != null) {
            receiveValue(Tuple2(publisherLatest, withLatest))
        }
    }
}

private class CombineLatest3<P0, P1, P2, Failure>(val publisher: Publisher<P0, Failure>, val with0: Publisher<P1, Failure>, val with1: Publisher<P2, Failure>): Publisher<Tuple3<P0, P1, P2>, Failure> {
    private var publisherLatest: P0? = null
    private var with0Latest: P1? = null
    private var with1Latest: P2? = null

    override fun sink(receiveValue: (Tuple3<P0, P1, P2>) -> Unit): AnyCancellable {
        val lock = this
        val publisherCancellable = publisher.sink { latest ->
            val publisherLatest: P0?
            val with0Latest: P1?
            val with1Latest: P2?
            synchronized(lock) {
                this.publisherLatest = latest
                publisherLatest = latest
                with0Latest = this.with0Latest
                with1Latest = this.with1Latest
            }
            sendLatest(receiveValue, publisherLatest, with0Latest, with1Latest)
        }
        val with0Cancellable = with0.sink { latest ->
            val publisherLatest: P0?
            val with0Latest: P1?
            val with1Latest: P2?
            synchronized(lock) {
                this.with0Latest = latest
                publisherLatest = this.publisherLatest
                with0Latest = latest
                with1Latest = this.with1Latest
            }
            sendLatest(receiveValue, publisherLatest, with0Latest, with1Latest)
        }
        val with1Cancellable = with1.sink { latest ->
            val publisherLatest: P0?
            val with0Latest: P1?
            val with1Latest: P2?
            synchronized(lock) {
                this.with1Latest = latest
                publisherLatest = this.publisherLatest
                with0Latest = this.with0Latest
                with1Latest = latest
            }
            sendLatest(receiveValue, publisherLatest, with0Latest, with1Latest)
        }
        return AnyCancellable {
            publisherCancellable.cancel()
            with0Cancellable.cancel()
            with1Cancellable.cancel()
        }
    }

    private fun sendLatest(receiveValue: (Tuple3<P0, P1, P2>) -> Unit, publisherLatest: P0?, with0Latest: P1?, with1Latest: P2?) {
        if (publisherLatest != null && with0Latest != null && with1Latest != null) {
            receiveValue(Tuple3(publisherLatest, with0Latest, with1Latest))
        }
    }
}

private class CombineLatest4<P0, P1, P2, P3, Failure>(val publisher: Publisher<P0, Failure>, val with0: Publisher<P1, Failure>, val with1: Publisher<P2, Failure>, val with2: Publisher<P3, Failure>): Publisher<Tuple4<P0, P1, P2, P3>, Failure> {
    private var publisherLatest: P0? = null
    private var with0Latest: P1? = null
    private var with1Latest: P2? = null
    private var with2Latest: P3? = null

    override fun sink(receiveValue: (Tuple4<P0, P1, P2, P3>) -> Unit): AnyCancellable {
        val lock = this
        val publisherCancellable = publisher.sink { latest ->
            val publisherLatest: P0?
            val with0Latest: P1?
            val with1Latest: P2?
            val with2Latest: P3?
            synchronized(lock) {
                this.publisherLatest = latest
                publisherLatest = latest
                with0Latest = this.with0Latest
                with1Latest = this.with1Latest
                with2Latest = this.with2Latest
            }
            sendLatest(receiveValue, publisherLatest, with0Latest, with1Latest, with2Latest)
        }
        val with0Cancellable = with0.sink { latest ->
            val publisherLatest: P0?
            val with0Latest: P1?
            val with1Latest: P2?
            val with2Latest: P3?
            synchronized(lock) {
                this.with0Latest = latest
                publisherLatest = this.publisherLatest
                with0Latest = latest
                with1Latest = this.with1Latest
                with2Latest = this.with2Latest
            }
            sendLatest(receiveValue, publisherLatest, with0Latest, with1Latest, with2Latest)
        }
        val with1Cancellable = with1.sink { latest ->
            val publisherLatest: P0?
            val with0Latest: P1?
            val with1Latest: P2?
            val with2Latest: P3?
            synchronized(lock) {
                this.with1Latest = latest
                publisherLatest = this.publisherLatest
                with0Latest = this.with0Latest
                with1Latest = latest
                with2Latest = this.with2Latest
            }
            sendLatest(receiveValue, publisherLatest, with0Latest, with1Latest, with2Latest)
        }
        val with2Cancellable = with2.sink { latest ->
            val publisherLatest: P0?
            val with0Latest: P1?
            val with1Latest: P2?
            val with2Latest: P3?
            synchronized(lock) {
                this.with2Latest = latest
                publisherLatest = this.publisherLatest
                with0Latest = this.with0Latest
                with1Latest = this.with1Latest
                with2Latest = latest
            }
            sendLatest(receiveValue, publisherLatest, with0Latest, with1Latest, with2Latest)
        }
        return AnyCancellable {
            publisherCancellable.cancel()
            with0Cancellable.cancel()
            with1Cancellable.cancel()
            with2Cancellable.cancel()
        }
    }

    private fun sendLatest(to: (Tuple4<P0, P1, P2, P3>) -> Unit, publisherLatest: P0?, with0Latest: P1?, with1Latest: P2?, with2Latest: P3?) {
        if (publisherLatest != null && with0Latest != null && with1Latest != null && with2Latest != null) {
            to(Tuple4(publisherLatest, with0Latest, with1Latest, with2Latest))
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