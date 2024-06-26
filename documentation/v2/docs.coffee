$(document).ready ->
  # Mobile navigation
  toggleSidebar = ->
    $('.menu-button, .row-offcanvas').toggleClass 'active'

  $('[data-toggle="offcanvas"]').click toggleSidebar

  $('[data-action="sidebar-nav"]').click (event) ->
    if $('.menu-button').is(':visible')
      event.preventDefault()
      toggleSidebar()
      setTimeout ->
        window.location = event.target.href
      , 260 # Wait for the sidebar to slide away before navigating


  # Initialize Scrollspy for sidebar navigation; http://v4-alpha.getbootstrap.com/components/scrollspy/
  # See also http://www.codingeverything.com/2014/02/BootstrapDocsSideBar.html and http://jsfiddle.net/KyleMit/v6zhz/
  $('body').scrollspy
    target: '#contents'
    offset: Math.round $('main').css('padding-top').replace('px', '')

  if window.location.hash?
    $(".nav-link.active[href!='#{window.location.hash}']").removeClass 'active'

  $(window).on 'activate.bs.scrollspy', (event, target) -> # Why `window`? https://github.com/twbs/bootstrap/issues/20086
    # We only want one active link in the nav
    $(".nav-link.active[href!='#{target.relatedTarget}']").removeClass 'active'
    $target = $(".nav-link[href='#{target.relatedTarget}']")
    # Update the browser address bar on scroll or navigation
    window.history.pushState {}, $target.text(), $target.prop('href')


  # Initialize CodeMirror for code examples; https://codemirror.net/doc/manual.html
  editors = []
  lastCompilationElapsedTime = 200
  $('textarea').each (index) ->
    $(@).data 'index', index
    mode = if $(@).hasClass('javascript-output') then 'javascript' else 'coffeescript'

    editors[index] = editor = CodeMirror.fromTextArea @,
      mode: mode
      theme: 'twilight'
      indentUnit: 2
      tabSize: 2
      lineWrapping: on
      lineNumbers: off
      inputStyle: 'contenteditable'
      readOnly: if mode is 'coffeescript' then no else 'nocursor'
      viewportMargin: Infinity

    # Whenever the user edits the CoffeeScript side of a code example, update the JavaScript output
    if mode is 'coffeescript'
      pending = null
      editor.on 'change', (instance, change) ->
        clearTimeout pending
        pending = setTimeout ->
          lastCompilationStartTime = Date.now()
          try
            output = CoffeeScript.compile editor.getValue(), bare: yes
            lastCompilationElapsedTime = Math.max(200, Date.now() - lastCompilationStartTime)
          catch exception
            output = "#{exception}"
          editors[index + 1].setValue output
        , lastCompilationElapsedTime


  # Handle the code example buttons
  $('[data-action="run-code-example"]').click ->
    run = $(@).data 'run'
    index = $("##{$(@).data('example')}-js").data 'index'
    js = editors[index].getValue()
    js = "#{js}\nalert(#{unescape run});" unless run is yes
    eval js
