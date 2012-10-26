Guard-Jasmine2JUnit
===================

A script that converts output from Guard-Jasmine to the XML format used by JUnit. This allows for running tests on continuos integration servers like Jenkins, complete with test reports!

## Prerequsites

### Ruby environment + Guard-Jasmine

Install guide: https://github.com/netzpirat/guard-jasmine#installation

Usage: https://github.com/netzpirat/guard-jasmine#usage

For Grunt based environments / build chains this seems like a good alternative: https://github.com/jasmine-contrib/grunt-jasmine-runner

### PhantomJS

Install guide: https://github.com/netzpirat/guard-jasmine#phantomjs

Massive caveat: Jenkins doesn't source the PATH from `~./profile` or `/etc/profile` or anywhere meaningful it seems, so in order to be able to use Homebrew installed PhantomJS you'll have to manually paste the contents of your $PATH (for example `/usr/local/bin:$PATH` + rbenv or rvm related bits if needed) into Jenkins Dashboard > Manage Jenkins > Configure System > Global properties / Environment variables > PATH.

## Command line execution

Running the test suite and generating the report can be as easy as one line in the Terminal:

`bundle exec guard-jasmine -p 8888 -u http://localhost:8888/ --console=never 2>&1 | guard-jasmine2junit.rb`

…unfortunately it's a no go on Jenkins as it can't handle piping so on to:

## Using Ant

```
<target name="test">
	<exec executable="bundle" dir="." output="test-temp.txt">
		<arg value="exec" />
		<arg value="guard-jasmine" />
		<arg value="-p" />
		<arg value="8888" />
		<arg value="-u" />
		<arg value="http://localhost:8888/" />
		<arg value="--console=never" />
	</exec>
	<exec executable="ruby" failonerror="true">
		<arg line="guard-jasmine2junit.rb test-temp.txt" />
	</exec>
</target>
```

You should only use `failonerror="true"` if you want the build to fail on any error, otherwise use the Jenkins [Performance Plugin](https://wiki.jenkins-ci.org/display/JENKINS/Performance+Plugin) to set warning and fail thresholds.
