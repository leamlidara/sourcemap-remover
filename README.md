# sourcemap-remover

A sample command-line application which allow you to remove \*.map files from your WebApp project.

## Why should you remove SourceMap files?

1. **Security**: SourceMap files contain a map of your original source code to the compiled code that is served to users. This can be a security risk, as it could allow attackers to reverse engineer your code and find vulnerabilities.
2. **Performance**: SourceMap files can increase the size of your production bundle, and can also slow down loading times.
3. **Privacy**: SourceMap files can contain sensitive information about your codebase, such as internal APIs and implementation details. You may not want to expose this information to users.

## How to build

```bash
git clone https://github.com/leamlidara/sourcemap-remover.git
cd sourcemap-remover/bin
dart compile exe sourcemap-remover.dart
```

OR you can download from below

[Download](https://github.com/leamlidara/sourcemap-remover/releases/)

## How to use

```bash
sourcemap-remover [option [directory path]]
sourcemap-remover.exe [option [directory path]]
```

### Note

If a directory path is not specified, the application will use the current directory.
