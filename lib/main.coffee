{Emitter,Disposable} = require('atom')
path                 = require('path')
CSON                 = require('season')

# ------------------------------------------------------------------------------

module.exports =

  ## Language package settings -------------------------------------------------

  config:
    generalSettings:
      type: 'object'
      order: 1
      properties:
        levelCodeFileTypes:
          title: 'Level Code File Type(s)'
          description:
            'A comma-separated list of file type extensions that are associated
            with this level language. This allows Levels to select the correct
            language when a file is opened or saved and no other language
            information is given. It\'s also possible to add a file type that is
            already associated with another installed grammar (e.g. `rb` for a
            Ruby-based level language).'
          type: 'array'
          default: []
          items:
            type: 'string'
    executionSettings:
      type: 'object'
      order: 2
      properties:
        executionCommandPatterns:
          title: 'Execution Command Pattern(s)'
          description:
            'A comma-separated list of patterns for the commands that will be
            executed (sequentially) to run your programs. Use the `<filePath>`
            variable to indicate where to insert the input file for each
            command. To run a generated executable file, add `./<filePath>` to
            the end of the list (e.g. `ghc -v0 <filePath>, ./<filePath>` for a
            Haskell-based level language).'
          type: 'array'
          default: []
          items:
            type: 'string'

  ## Language package activation and deactivation ------------------------------

  activate: ->
    @emitter = new Emitter

    @pkgDirPath = path.dirname(__dirname)
    pkgMetadataFilePath = CSON.resolve(path.join(@pkgDirPath,'package'))
    @pkgMetadata = CSON.readFileSync(pkgMetadataFilePath)

    @configFilePath = @getConfigFilePath()
    @executablePath = @getExecutablePath()

    pkgSubscr = atom.packages.onDidActivatePackage (pkg) =>
      if pkg.name is @pkgMetadata.name
        @dummyGrammar = pkg.grammars[0]
        atom.grammars.removeGrammar(@dummyGrammar)
        @startUsingLevels() if @levelsIsActive
        @onDidActivateLevels => @startUsingLevels()
        @onDidDeactivateLevels => @stopUsingLevels()
        pkgSubscr.dispose()

  deactivate: ->
    @languageRegistry.removeLanguage(@language) if @levelsIsActive

  ## Activation helpers --------------------------------------------------------

  getConfigFilePath: ->
    CSON.resolve(path.join(@pkgDirPath,'language','config'))

  getExecutablePath: ->
    executableDirPath = path.join(@pkgDirPath,'language','executable')
    switch process.platform
      when 'darwin' then path.join(executableDirPath,'darwin','run')
      when 'linux'  then path.join(executableDirPath,'linux','run')
      when 'win32'  then path.join(executableDirPath,'win32','run.exe')

  ## Interacting with the Levels package ---------------------------------------

  onDidActivateLevels: (callback) ->
    @emitter.on('did-activate-levels',callback)

  onDidDeactivateLevels: (callback) ->
    @emitter.on('did-deactivate-levels',callback)

  consumeLevels: ({@languageRegistry}) ->
    @levelsIsActive = true
    @emitter.emit('did-activate-levels')
    new Disposable =>
      @levelsIsActive = false
      @emitter.emit('did-deactivate-levels')

  startUsingLevels: ->
    unless @language?
      try
        @language = @languageRegistry.readLanguageSync\
          (@configFilePath,@executablePath)
        @dummyGrammar.name = @language.getGrammarName()
        @dummyGrammar.scopeName = @language.getScopeName()
        @dummyGrammar.fileTypes = @language.getLevelCodeFileTypes()
        @language.setDummyGrammar(@dummyGrammar)
        @setUpLanguageConfigurationManagement()
      catch error
        console.log error
    whitelistPath = path.join(@pkgDirPath,'language','whitelist')
    process.env['LRB_WHITELIST_PATH'] = whitelistPath
    atom.grammars.addGrammar(@dummyGrammar)
    @languageRegistry.addLanguage(@language)

  stopUsingLevels: ->
    atom.grammars.removeGrammar(@dummyGrammar)
    delete process.env['LRB_WHITELIST_PATH']

  ## Language configuration management -----------------------------------------

  setUpLanguageConfigurationManagement: ->
    pkgName = @pkgMetadata.name

    configKeyPath = "#{pkgName}.generalSettings.levelCodeFileTypes"
    if (levelCodeFileTypes = atom.config.get(configKeyPath)).length > 0
      @language.setLevelCodeFileTypes(levelCodeFileTypes)
    else
      atom.config.set(configKeyPath,@language.getLevelCodeFileTypes())
    atom.config.onDidChange configKeyPath, ({newValue}) =>
      @language.setLevelCodeFileTypes(newValue)

    configKeyPath = "#{pkgName}.executionSettings.executionCommandPatterns"
    if (executionCommandPatterns = atom.config.get(configKeyPath)).length > 0
      @language.setExecutionCommandPatterns(executionCommandPatterns)
    else
      atom.config.set(configKeyPath,@language.getExecutionCommandPatterns())
    atom.config.onDidChange configKeyPath, ({newValue}) =>
      @language.setExecutionCommandPatterns(newValue)

# ------------------------------------------------------------------------------
