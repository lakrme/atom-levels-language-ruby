{CompositeDisposable,Disposable} = require('atom')
path                             = require('path')
CSON                             = require('season')

# ------------------------------------------------------------------------------

module.exports =

  ## Language package activation and deactivation ------------------------------

  activate: ->
    @pkgDirPath = path.dirname(__dirname)
    pkgMetadataFilePath = CSON.resolve(path.join(@pkgDirPath,'package'))
    @pkgMetadata = CSON.readFileSync(pkgMetadataFilePath)

    @configFilePath = @getConfigFilePath()
    @executablePath = @getExecutablePath()

    pkgSubscr = atom.packages.onDidActivatePackage (pkg) =>
      if pkg.name is @pkgMetadata.name
        @dummyGrammar = pkg.grammars[0]
        atom.grammars.removeGrammar(@dummyGrammar)
        @startUsingLevels() if @consumedLevels
        pkgSubscr.dispose()
        @activated = true

  deactivate: ->
    @levelsBinding?.dispose()
    @activated = false

  ## Activation helpers --------------------------------------------------------

  getConfigFilePath: ->
    CSON.resolve(path.join(@pkgDirPath,'language','config'))

  getExecutablePath: ->
    executableDirPath = path.join(@pkgDirPath,'language','executables')
    switch process.platform
      when 'darwin' then path.join(executableDirPath,'darwin','run')
      when 'linux'  then path.join(executableDirPath,'linux','run')
      when 'win32'  then path.join(executableDirPath,'win32','run.exe')

  ## Interacting with the Levels package ---------------------------------------

  consumeLevels: ({@languageRegistry,@notificationUtils}) ->
    if @activated
      @startUsingLevels()
    @consumedLevels = true
    @levelsBinding = new Disposable =>
      @stopUsingLevels()
      @consumedLevels = false

  startUsingLevels: ->
    unless @usingLevels
      try
        unless @language?
          @language = @languageRegistry.readLanguageSync\
            (@configFilePath,@executablePath)
          @dummyGrammar.name = @language.getGrammarName()
          @dummyGrammar.scopeName = @language.getScopeName()
          @dummyGrammar.fileTypes = @language.getLevelCodeFileTypes()
          @language.setDummyGrammar(@dummyGrammar)
        atom.grammars.addGrammar(@dummyGrammar)
        @languageRegistry.addLanguage(@language)
        @usingLevels = true
        @onDidStartUsingLevels()
      catch error
        atom.notifications.addError \
          "Failed to load the language from the #{@pkgMetadata.name} package",
          detail: error.toString(),
          dismissable: true

  stopUsingLevels: ->
    if @usingLevels
      atom.grammars.removeGrammar(@dummyGrammar)
      @languageRegistry.removeLanguage(@language)
      @usingLevels = false
      @onDidStopUsingLevels()

  onDidStartUsingLevels: ->
    @setUpConfigManagement()
    whitelistPath = path.join(@pkgDirPath,'language','whitelist')
    process.env['LRB_WHITELIST_PATH'] = whitelistPath

  onDidStopUsingLevels: ->
    @configSubscrs.dispose()
    delete process.env['LRB_WHITELIST_PATH']

  ## Language configuration management -----------------------------------------

  config:
    rubyInterpreterDirectoryPath:
      title: 'Ruby Interpreter Directory Path'
      description:
        'The path to the directory that contains the Ruby interpreter (a file
        named `ruby` on Mac OS X/Linux and `ruby.exe` on Windows, respectively).
        If no path is given, the `PATH` environment variable will be checked
        automatically.'
      type: 'string'
      default: ''

  setUpConfigManagement: ->
    @configSubscrs = new CompositeDisposable

    configKeyPath = "#{@pkgMetadata.name}.rubyInterpreterDirectoryPath"
    if (rubyInterpreterDirectoryPath = atom.config.get(configKeyPath).trim())
      rubyInterpreterPath = path.join(rubyInterpreterDirectoryPath,'ruby')
      executionCommandPatterns = ["#{rubyInterpreterPath} <filePath>"]
      @language.setExecutionCommandPatterns(executionCommandPatterns)
    else
      @language.setExecutionCommandPatterns(["ruby <filePath>"])
    @configSubscrs = atom.config.onDidChange configKeyPath, ({newValue}) =>
      if (rubyInterpreterDirectoryPath = newValue.trim())
        rubyInterpreterPath = path.join(rubyInterpreterDirectoryPath,'ruby')
        executionCommandPatterns = ["#{rubyInterpreterPath} <filePath>"]
        @language.setExecutionCommandPatterns(executionCommandPatterns)
      else
        @language.setExecutionCommandPatterns(["ruby <filePath>"])

# ------------------------------------------------------------------------------
