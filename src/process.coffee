$.ready(
  client = null
  getWSServers((err, list) =>
    test = false
    n = -1;
    async.until(()=>
      n++
      return test || n>=list.length
    ,(callback)=>
      client = new W3CWebSocket list[n]
      client.onerror = () =>
        console.log "Connection Error"
        callback null
      client.onopen = () =>
        console.log('WebSocket Client Connected');
        test = true
        callback null
      client.onclose = () =>
        console.log("Connection Closed")
        callback null
      client.onmessage = (e) =>
        console.log e.data
        if typeof e.data is "string"
          if e.data is "2::"
            client.send "2::"
      return
    ,(err, n)=>
      return
    ))
)
