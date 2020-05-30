'use babel';

import path from 'path';

export default {
  activate() {
    this.pkgName = 'levels-language-ruby';
    const pkgDirPath = atom.packages.resolvePackagePath(this.pkgName);
    this.pkgLanguageDirPath = path.join(pkgDirPath, 'language');

    const pkgSubscription = atom.packages.onDidActivatePackage(pkg => {
      if (pkg.name === this.pkgName) {
        if (this.consumedLevels) {
          this.startUsingLevels();
        }

        pkgSubscription.dispose();
        this.activated = true;
      }
    });
  },

  deactivate() {
    this.stopUsingLevels();
    this.consumedLevels = false;
    this.activated = false;
  },

  consumeLevels({languageRegistry}) {
    this.languageRegistry = languageRegistry;
    if (this.activated) {
      this.startUsingLevels();
    }
    this.consumedLevels = true;
  },

  startUsingLevels() {
    if (!this.usingLevels) {
      try {
        if (!this.language) {
          const configFilePath = path.join(this.pkgLanguageDirPath, 'config.json');
          const executable = process.platform === 'win32' ? 'run.exe' : 'run';
          const executablePath = path.join(this.pkgLanguageDirPath, 'executables', process.platform, executable);
          const dummyGrammarPath = path.join(this.pkgLanguageDirPath, 'grammars', 'dummy.json');
          this.dummyGrammar = atom.grammars.readGrammarSync(dummyGrammarPath);
          this.language = this.languageRegistry.readLanguageSync(configFilePath, executablePath);
          this.dummyGrammar.name = this.language.getGrammarName();
          this.dummyGrammar.scopeName = this.language.getScopeName();
          this.dummyGrammar.fileTypes = this.language.getLevelCodeFileTypes();
          this.language.setDummyGrammar(this.dummyGrammar);
        }

        this.grammarSubscription = atom.grammars.addGrammar(this.dummyGrammar);
        this.languageRegistry.addLanguage(this.language);

        this.usingLevels = true;
        this.setUpConfigManagement();
        process.env.LRB_WHITELIST_PATH = path.join(this.pkgLanguageDirPath, 'whitelist');
      } catch (error) {
        atom.notifications.addFatalError(`Failed to load the language from the ${this.pkgName} package`, {
          detail: error.message,
          stack: error.stack,
          dismissable: true
        });
      }
    }
  },

  stopUsingLevels() {
    if (this.usingLevels) {
      this.grammarSubscription.dispose();
      this.languageRegistry.removeLanguage(this.language);
      this.usingLevels = false;
      this.configSubscription.dispose();
      delete process.env.LRB_WHITELIST_PATH;
    }
  },

  config: {
    rubyInterpreterDirectoryPath: {
      title: 'Ruby Interpreter Directory Path',
      description: `The path to the directory that contains the Ruby interpreter
        (a file named \`ruby\` on macOS or Linux and \`ruby.exe\` on Windows, respectively).
        If no path is given, the \`PATH\` environment variable will be checked automatically.`,
      type: 'string',
      default: ''
    }
  },

  setExecutionCommandPatterns(directory) {
    const rubyInterpreterPath = path.join(directory.trim(), 'ruby');
    this.language.setExecutionCommandPatterns([`${rubyInterpreterPath} <filePath>`]);
  },

  setUpConfigManagement() {
    const configKeyPath = `${this.pkgName}.rubyInterpreterDirectoryPath`;
    this.setExecutionCommandPatterns(atom.config.get(configKeyPath));
    this.configSubscription = atom.config.onDidChange(configKeyPath, ({newValue}) => {
      this.setExecutionCommandPatterns(newValue);
    });
  }
};