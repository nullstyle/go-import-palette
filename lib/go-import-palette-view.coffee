_ = require 'underscore-plus'
fs = require 'fs-plus'
{SelectListView, $, $$} = require 'atom-space-pen-views'
{match} = require 'fuzzaldrin'
{BufferedProcess} = require 'atom'

module.exports =
class GoImportPaletteView extends SelectListView
  @activate: ->
    view = new GoImportPaletteView
    @disposable = atom.commands.add 'atom-workspace', 'go-import-palette:toggle', -> view.toggle()

  @deactivate: ->
    @disposable.dispose()

  initialize: ->
    super
    @addClass('go-import-palette')
    @refreshPackages()

  refreshPackages: ->
    output = ""
    options =
      command: "go",
      args: ["list", "..."],
      cwd: atom.project.rootDirectories[0].path
      stdout: (o) ->
        output = o
      exit: (code) =>
        throw "Couldn't list go packages: #{output}" if code != 0
        packages = ({name:p} for p in output.split("\n"))
        @setItems(packages)

    new BufferedProcess(options)


  getFilterKey: ->
    'name'

  cancelled: -> @hide()

  toggle: ->
    if @panel?.isVisible()
      @cancel()
    else
      @show()

  show: ->
    @panel ?= atom.workspace.addModalPanel(item: this)
    @panel.show()

    @focusFilterEditor()

  hide: ->
    @panel?.hide()

  viewForItem: ({name}) ->
    # Style matched characters in search results
    filterQuery = @getFilterQuery()
    matches = match(name, filterQuery)

    $$ ->
      highlighter = (p, matches, offsetIndex) =>
        lastIndex = 0
        matchedChars = [] # Build up a set of matched chars to be more semantic

        for matchIndex in matches
          matchIndex -= offsetIndex
          continue if matchIndex < 0 # If marking up the basename, omit command matches
          unmatched = p.substring(lastIndex, matchIndex)
          if unmatched
            @span matchedChars.join(''), class: 'character-match' if matchedChars.length
            matchedChars = []
            @text unmatched
          matchedChars.push(p[matchIndex])
          lastIndex = matchIndex + 1

        @span matchedChars.join(''), class: 'character-match' if matchedChars.length

        # Remaining characters are plain text
        @text p.substring(lastIndex)

      @li class: 'event', 'data-event-name': name, =>
        @span title: name, -> highlighter(name, matches, 0)

  confirmed: ({name}) ->
    @cancel()
    console.log("adding #{name} to file")
