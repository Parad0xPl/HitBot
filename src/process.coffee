$(document).ready( ()->
  navButtons = $(".nav a")
  navButtons.click () ->
    id = $(this).attr "id"
    viewport = $("div#viewport div##{id}")
    viewport.css "display", "block"
    viewport.siblings().css "display", "none"
    return
  return
)
