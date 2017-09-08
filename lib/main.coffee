path = require 'path'
CSON = require 'season'

module.exports =
  activate: ->
    @pkgName = 'levels-language-ruby'
    pkgDirPath = atom.packages.resolvePackagePath @pkgName
    @pkgLanguageDirPath = path.join pkgDirPath, 'language'

    @configFilePath = CSON.resolve path.join @pkgLanguageDirPath, 'config'
    @executablePath = @getExecutablePath()

    pkgSubscription = atom.packages.onDidActivatePackage (pkg) =>
      if pkg.name == @pkgName
        dummyGrammarPath = path.join @pkgLanguageDirPath, 'grammars', 'dummy.cson'
        @dummyGrammar = atom.grammars.readGrammarSync dummyGrammarPath

        if @consumedLevels
          @startUsingLevels()

        pkgSubscription.dispose()
        @activated = true

  deactivate: ->
    @stopUsingLevels()
    @consumedLevels = false
    @activated = false

  getExecutablePath: ->
    executableDirPath = path.join @pkgLanguageDirPath, 'executables'
    executable = if process.platform == 'win32' then 'run.exe' else 'run'
    return path.join executableDirPath, process.platform, executable

  consumeLevels: ({@languageRegistry}) ->
    if @activated
      @startUsingLevels()
    @consumedLevels = true

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
        @onDidStartUsingLevels()
      catch error
        atom.notifications.addError "Failed to load the language from the #{@pkgName} package",
          detail: "#{error}"
          dismissable: true

  stopUsingLevels: ->
    if @usingLevels
      atom.grammars.removeGrammar @dummyGrammar
      @languageRegistry.removeLanguage @language
      @usingLevels = false
      @onDidStopUsingLevels()

  onDidStartUsingLevels: ->
    @setUpConfigManagement()
    process.env['LRB_WHITELIST_PATH'] = path.join @pkgLanguageDirPath, 'whitelist'

  onDidStopUsingLevels: ->
    @configSubscription.dispose()
    delete process.env['LRB_WHITELIST_PATH']

  config:
    rubyInterpreterDirectoryPath:
      title: 'Ruby Interpreter Directory Path'
      description: 'The path to the directory that contains the Ruby interpreter
        (a file named `ruby` on macOS or Linux and `ruby.exe` on Windows, respectively).
        If no path is given, the `PATH` environment variable will be checked automatically.'
      type: 'string'
      default: ''

  setUpConfigManagement: ->
    configKeyPath = "#{@pkgName}.rubyInterpreterDirectoryPath"

    if rubyInterpreterDirectoryPath = atom.config.get(configKeyPath).trim()
      rubyInterpreterPath = path.join rubyInterpreterDirectoryPath, 'ruby'
      @language.setExecutionCommandPatterns ["#{rubyInterpreterPath} <filePath>"]
    else
      @language.setExecutionCommandPatterns ['ruby <filePath>']

    @configSubscription = atom.config.onDidChange configKeyPath, ({newValue}) =>
      if rubyInterpreterDirectoryPath = newValue.trim()
        rubyInterpreterPath = path.join rubyInterpreterDirectoryPath, 'ruby'
        @language.setExecutionCommandPatterns ["#{rubyInterpreterPath} <filePath>"]
      else
        @language.setExecutionCommandPatterns ['ruby <filePath>']