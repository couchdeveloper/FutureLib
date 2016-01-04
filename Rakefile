
def git_has_uncommitted_changes
    return system("git diff-index --quiet --cached HEAD") == false
end

def git_has_dirty_workspace
    return system("git diff-files --quiet") == false
end

def git_has_untracked_files
    return `git ls-files --exclude-standard --others`.length > 0
end


def git_is_status_clean
    return `git status --porcelain`.empty?
end


desc "Runs the specs [EMPTY]"
task :spec do
  # Provide your own implementation
end


$workspace = "FutureLib.xcworkspace"
$schemes = ['FutureLib', 'FutureLib-iOS', 'FutureLib-tvOS', 'FutureLib-watchOS']
$benches = ['FutureLibPerformanceTests']


desc "Build all targets defined within the given schemes #{$schemes}"
task :build do
    $schemes.each { |scheme|
        sh "xctool -workspace #{$workspace} -scheme #{scheme} build"
    }
end

desc "Clean all targets defined within the given schemes #{$schemes}"
task :clean do
    $schemes.each { |scheme|
        sh "xctool -workspace #{$workspace} -scheme #{scheme} clean"
    }
end


desc "Build all tests defined within the given schemes #{$schemes}"
task :build_tests do
    $schemes.each { |scheme|
        sh "xctool -workspace #{$workspace} -scheme #{scheme} build-tests"
    }
end

desc "Run all tests defined within the given schemes #{$schemes}"
task :test  => :build_tests do
    $schemes.each { |scheme|
        sh "xctool -workspace #{$workspace} -scheme #{scheme} run-tests"
    }
end

desc "Run all tests defined within the given schemes #{$schemes}"
task :run_tests do
    $schemes.each { |scheme|
        sh "xctool -workspace #{$workspace} -scheme #{scheme} run-tests"
    }
end


desc "Build an run all benchmark tests defined within the given schemes #{$benches}"
task :bench do
    $benches.each { |scheme|
        sh "xctool -workspace #{$workspace} -scheme #{scheme} test"
    }
end
