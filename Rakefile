
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


$workspace = "FutureLib.xcworkspace"
$allSchemes = ['FutureLib-MacOS', 'FutureLib-iOS', 'FutureLib-tvOS', 'FutureLib-watchOS']
$testSchemes = ['FutureLib-MacOS', 'FutureLib-iOS', 'FutureLib-tvOS']
$benchmarkSchemes = ['FutureLibPerformanceTests']


desc "Build all targets defined within the given schemes #{$allSchemes}"
task :build do
    $allSchemes.each { |scheme|
        sh "xctool -workspace #{$workspace} -scheme #{scheme} build"
    }
end

desc "Clean all targets defined within the given schemes #{$allSchemes}"
task :clean do
    $allSchemes.each { |scheme|
        sh "xctool -workspace #{$workspace} -scheme #{scheme} clean"
    }
end



desc "Run all tests defined within the given schemes"
task :test  do
    sh "xcrun xcodebuild test -workspace FutureLib.xcworkspace -scheme FutureLib-MacOS -destination 'arch=x86_64'| xcpretty"
    sh "xcrun xcodebuild test -workspace FutureLib.xcworkspace -scheme FutureLib-iOS -destination 'platform=iOS Simulator,name=iPhone 6' test | xcpretty"
    sh "xcrun xcodebuild test -workspace FutureLib.xcworkspace -scheme FutureLib-tvOS -destination 'platform=tvOS Simulator,name=Apple TV 1080p' test | xcpretty"
end



desc "Build and run all benchmark tests defined within the given schemes"
task :bench do
    sh "xcrun xcodebuild test -workspace FutureLib.xcworkspace -scheme FutureLibPerformanceTests -destination 'arch=x86_64'| xcpretty"
end
