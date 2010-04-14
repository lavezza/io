Object do(
  /*doc Object inlineMethod
  Creates a method which is executed directly in a receiver (no Locals object is created).
  <br/>
  <pre>
  Io> m := inlineMethod(x := x*2)
  Io> x := 1
  ==> 1
  Io> m
  ==> 2
  Io> m
  ==> 4
  Io> m
  ==> 8
  </pre>
  */
    inlineMethod := method(call message argAt(0) setIsActivatable(true))
)

List do(
    unique := method(
        u := List clone
        self foreach(v, u appendIfAbsent(v))
        u
    )

    /*doc List selectInPlace(optionalIndex, value, message)
    Like foreach, but the values for which the result of message is either nil
    or false are removed from the List. Example:
<code>list(1, 5, 7, 2) selectInPlace(i, v, v > 3) print
==> 5, 7
list(1, 5, 7, 2) selectInPlace(v, v > 3) print
 ==> 5, 7</code>
*/
    selectInPlace := method(
        # Creating a context, in which the body would be executed in.
        # Note: since call sender isn't the actual sender object, but
        # rather a proxy, we need to prepend the value of it's self slot,
        # to get the desired behaviour.
        context := Object clone prependProto(call sender self)
        # Offset, applied to get the real index of the elements being
        # deleted.
        offset := 0
        argCount := call argCount

        if(argCount == 0, Exception raise("missing argument"))
        if(argCount == 1) then(
            body := call argAt(0)
            size repeat(idx,
                if(at(idx - offset) doMessage(body, context) not,
                    removeAt(idx - offset)
                    offset = offset + 1
                )
            )
        ) elseif(argCount == 2) then(
            eName := call argAt(0) name # Element.
            body  := call argAt(1)
            size repeat(idx,
                context setSlot(eName, at(idx - offset))
                if(context doMessage(body) not,
                    removeAt(idx - offset)
                    offset = offset + 1
                )
            )
        ) else(
            iName := call argAt(0) name # Index.
            eName := call argAt(1) name # Element.
            body  := call argAt(2)

            size repeat(idx,
                context setSlot(iName, idx)
                context setSlot(eName, at(idx - offset))
                if(context doMessage(body) not,
                    removeAt(idx - offset)
                    offset = offset + 1
                )
            )
        )
        self
    )

    //doc List select Same as <tt>selectInPlace</tt>, but result is a new List.
    select := method(
        call delegateToMethod(self clone, "selectInPlace")
    )

    /*doc List detect(optionalIndex, value, message)
    Returns the first value for which the message evaluates to a non-nil. Example:
<code>list(1, 2, 3, 4) detect(i, v, v > 2)
==> 3
list(1, 2, 3, 4) detect(v, v > 2)
==> 3</code>
*/
    detect := method(
        a1 := call argAt(0)
        if(a1 == nil, Exception raise("missing argument"))
        a2 := call argAt(1)
        a3 := call argAt(2)

        if(a3,
            a1 := a1 name
            a2 := a2 name
            self foreach(i, v,
                call sender setSlot(a1, i)
                call sender setSlot(a2, getSlot("v"))
                ss := stopStatus(c := a3 doInContext(call sender, call sender))
                if(ss isReturn, ss return getSlot("c"))
                if(ss stopLooping, break)
                if(ss isContinue, continue)
                if(getSlot("c"), return getSlot("v"))
            )
            return nil
        )

        if(a2,
            a1 := a1 name
            self foreach(v,
                call sender setSlot(a1, getSlot("v"))
                ss := stopStatus(c := a2 doInContext(call sender, call sender))
                if(ss isReturn, ss return getSlot("c"))
                if(ss stopLooping, break)
                if(ss isContinue, continue)
                if(getSlot("c"), return getSlot("v"))
            )
            return nil
        )

        self foreach(v,
            ss := stopStatus(c := a1 doInContext(getSlot("v"), call sender))
            if(ss isReturn, ss return getSlot("c"))
            if(ss stopLooping, break)
            if(ss isContinue, continue)
            if(getSlot("c"), return getSlot("v"))
        )
        nil
    )

    //doc List map(optionalIndex, value, message) Same as calling mapInPlace() on a clone of the receiver, but more efficient.
    map := method(
        aList := List clone

        a1 := call argAt(0)
        if(a1 == nil, Exception raise("missing argument"))
        a2 := call argAt(1)
        a3 := call argAt(2)

        if(a2 == nil,
            self foreach(v,
                ss := stopStatus(c := a1 doInContext(getSlot("v"), call sender))
                if(ss isReturn, ss return getSlot("c"))
                if(ss stopLooping, break)
                if(ss isContinue, continue)
                aList append(getSlot("c"))
            )
            return aList
        )

        if(a3 == nil,
            a1 := a1 name
            self foreach(v,
                call sender setSlot(a1, getSlot("v"))
                ss := stopStatus(c := a2 doInContext(call sender, call sender))
                if(ss isReturn, ss return getSlot("c"))
                if(ss stopLooping, break)
                if(ss isContinue, continue)
                aList append(getSlot("c"))
            )
            return aList
        )

        a1 := a1 name
        a2 := a2 name
        self foreach(i, v,
            call sender setSlot(a1, i)
            call sender setSlot(a2, getSlot("v"))
            ss := stopStatus(c := a3 doInContext(call sender, call sender))
            if(ss isReturn, ss return getSlot("c"))
            if(ss stopLooping, break)
            if(ss isContinue, continue)
            aList append(getSlot("c"))
        )
        return aList
    )

    groupBy := method(
        aMap := Map clone

        a1 := call argAt(0)
        if(a1 == nil, Exception raise("missing argument"))
        a2 := call argAt(1)
        a3 := call argAt(2)

        if(a2 == nil,
            self foreach(v,
                ss := stopStatus(c := a1 doInContext(getSlot("v"), call sender))
                if(ss isReturn, ss return getSlot("c"))
                if(ss stopLooping, break)
                if(ss isContinue, continue)

                key := getSlot("c") asString

                aMap atIfAbsentPut(key, list())
                aMap at(key) append(v)
            )
            return aMap
        )

        if(a3 == nil,
            a1 := a1 name
            self foreach(v,
                call sender setSlot(a1, getSlot("v"))
                ss := stopStatus(c := a2 doInContext(call sender, call sender))
                if(ss isReturn, ss return getSlot("c"))
                if(ss stopLooping, break)
                if(ss isContinue, continue)

                key := getSlot("c") asString

                aMap atIfAbsentPut(key, list())
                aMap at(key) append(v)
            )
            return aMap
        )

        a1 := a1 name
        a2 := a2 name
        self foreach(i, v,
            call sender setSlot(a1, i)
            call sender setSlot(a2, getSlot("v"))
            ss := stopStatus(c := a3 doInContext(call sender, call sender))
            if(ss isReturn, ss return getSlot("c"))
            if(ss stopLooping, break)
            if(ss isContinue, continue)

            key := getSlot("c") asString

            aMap atIfAbsentPut(key, list())
            aMap at(key) append(v)
        )
        return aMap
    )

    //doc List copy(v) Replaces self with <tt>v</tt> list items. Returns self.
    copy := method(v, self empty; self appendSeq(v); self)

    //doc List mapInPlace Same as <tt>map</tt>, but result replaces self.
    mapInPlace := method(
        self copy(self getSlot("map") performOn(self, call sender, call message))
    )

    empty := method(self removeAll)

    isEmpty := method(size == 0)
    isNotEmpty := method(size > 0)

    //doc List reverse Reverses the ordering of all the items of the receiver. Returns copy of receiver.
    reverse := method(itemCopy reverseInPlace)

    //doc List itemCopy Returns a new list containing the items from the receiver.
    itemCopy := method(List clone copy(self))

    sort := method(self clone sortInPlace)
    sortBy := method(b, self clone sortInPlaceBy(getSlot("b")))

    //doc List second Returns second element (same as <tt>at(1)</tt>)
    second := method(at(1))
    //doc List second Returns third element (same as <tt>at(2)</tt>)
    third := method(at(2))
)