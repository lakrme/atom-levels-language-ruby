path = require 'path'
CSON = require 'season'

module.exports =
  activate: ->
    @pkgName = 'levels-language-ruby'
    pkgDirPath = atom.packages.resolvePackagePath @pkgName
    @pkgLanguageDirPath = path.join pkgDirPath, 'language'

    @configFilePath = CSON.resolve path.join @pkgLanguageDirPath, 'config'
    executable = if process.platform == 'win32' then 'run.exe' else 'run'
    @executablePath = path.join @pkgLanguageDirPath, 'executables', process.platform, executable

    dummyGrammarPath = CSON.resolve path.join @pkgLanguageDirPath, 'grammars', 'dummy'
    @dummyGrammar = atom.grammars.readGrammarSync dummyGrammarPath

    pkgSubscription = atom.packages.onDidActivatePackage (pkg) =>
      if pkg.name == @pkgName
        if @consumedLevels
          @startUsingLevels()

        pkgSubscription.dispose()
        @activated = true

    return

  deactivate: ->
    @stopUsingLevels()
    @consumedLevels = false
    @activated = false
    return

  consumeLevels: ({@languageRegistry}) ->
    if @activated
      @startUsingLevels()
    @consumedLevels = true
    return

  startUsingLevels: ->
    if !@usingLevels
      try
        if !@language
          @language = @languageRegistry.readLanguageSync @configFilePath, @executablePath
          @dummyGrammar.name = @language.getGrammarName()
          @dummyGrammar.scopeName = @language.getScopeName()
          @dummyGrammar.fileTypes = @language.getLevelCodeFileTypes()
          @language.setDummyGrammar @dummyGrammar

        atom.grammars.addGrammar @dummyGrammar
        @languageRegistry.addLanguage @language

        @usingLevels = true
        @setUpConfigManagement()
        process.env['LRB_WHITELIST_PATH'] = path.join @pkgLanguageDirPath, 'whitelist'
      catch error
        atom.notifications.addError "Failed to load the language from the #{@pkgName} package",
          detail: "#{error}"
          dismissable: true
    return

  stopUsingLevels: ->
    if @usingLevels
      atom.grammars.removeGrammar @dummyGrammar
      @languageRegistry.removeLanguage @language
      @usingLevels = false
      @configSubscription.dispose()
      delete process.env['LRB_WHITELIST_PATH']
    return

  config:
    rubyInterpreterDirectoryPath:
      title: 'Ruby Interpreter Directory Path'
      description: 'The path to the directory that contains the Ruby interpreter
        (a file named `ruby` on macOS or Linux and `ruby.exe` on Windows, respectively).
        If no path is given, the `PATH` environment variable will be checked automatically.'
      type: 'string'
      default: ''

  setExecutionCommandPatterns: (directory) ->
    if rubyInterpreterDirectoryPath = directory.trim()
      rubyInterpreterPath = path.join rubyInterpreterDirectoryPath, 'ruby'
      @language.setExecutionCommandPatterns ["#{rubyInterpreterPath} <filePath>"]
    else
      @language.setExecutionCommandPatterns ['ruby <filePath>']
    return

  setUpConfigManagement: ->
    configKeyPath = "#{@pkgName}.rubyInterpreterDirectoryPath"
    @setExecutionCommandPatterns atom.config.get configKeyPath
    @configSubscription = atom.config.onDidChange configKeyPath, ({newValue}) =>
      @setExecutionCommandPatterns newValue
    return