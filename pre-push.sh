#!/bin/sh

if $(which bundle &> /dev/null); then
        echo "BUNDLE fastlane"
	bundle exec fastlane ci || exit 0
elif $(which fastlane &> /dev/null); then
	fastlane ci
else
	echo 'Fastlane not installed; Run `bundle install` or install Fastlane directly'
	exit 1
fi
