#------------------------------------------------
#	Update rails engine script
#------------------------------------------------
# Author: Evgeniy Bazurov (c)2016 
#
# Description: Short way to update the engine
# Its necessay to have an *.sh script for execute
#
#------------------------------------------------

import re
import cmd
import os
import subprocess

#------------------------------------------------
# Base function
#------------------------------------------------

def update():

	print "--------------------------------------------"
	print "-- Lets start updating process"
	print "--------------------------------------------"
	
	# -- Get current execution directory
	curdir =  os.getcwd()
	versionfile = ''
	
	# -- Find the version.rb
	for root, dirs, files in os.walk(curdir+"/lib"):
		for file in files:
			if file.endswith("version.rb"):
				versionfile = os.path.join(root,file)
	versionF = open(versionfile,'r+').read()
	
	# -- find version number for parsing
	version = re.findall('\"([0-9.]+)\"', versionF)
	
	# -- parse
	v = re.findall('([0-9]+)+.([0-9]+)+.([0-9]+)+', version[0])
	major =  v[0][0]
	minor = v[0][1]
	build = v[0][2]
	print 'Current version of module is: '+ major+"."+minor+"."+build
	
	# -- newVersion function needs array. Let's do that!
	ver=[]
	ver.append(int(v[0][0]))
	ver.append(int(v[0][1]))
	ver.append(int(v[0][2]))

	# -- For testing purposes
	#	ver.append(0)
	#	ver.append(1)
	#	ver.append(7)

	# -- calculate version
	v = mversion(ver)
	newVersion=str(v[0])+"."+str(v[1])+"."+str(v[2])
	
	# -- replace version in file
	prs=re.sub('\"([0-9.]+)\"',"\""+newVersion+"\"",versionF)
	versionF = open(versionfile,'r+')
	versionF.truncate()
	
	# -- write new content of the file to version.rb
	versionF.write(prs)
	versionF.close()

	print 'Making new version of module : '+newVersion
	
	# -- git manipulation
	os.system("git add . ")
	os.system("git commit -m 'New gem version: "+str(v[0])+"."+str(v[1])+"."+str(v[2])+"' ")
	
	try:
		subprocess.check_output("git push origin master",stderr=subprocess.STDOUT, shell = True)
	except subprocess.CalledProcessError, e:
		print "Error: \n", e.output
		return

	# -- get gemspec engine file
	for root, dirs, files in os.walk(curdir):
		for file in files:
			if file.endswith(".gemspec"):
				gemfile = file
	
	# -- build the gem
	os.system("gem build "+gemfile)
	name=os.path.splitext(gemfile)[0]+"-"+newVersion+".gem"
	print "Uploading "+ name
	
	# -- send gem to a custom gemstorage
	try:
		os.system("gem inabox "+name)
	except subprocess.CalledProcessError, e:
		print "Error while uploading gem: \n", e.output
		return
	print "Gem is updated"
	
	#------------------------------------------------
	# calculate proper version from version.rb
	#------------------------------------------------

def mversion(v):

	if v[2] == 9:
		v[2] = 0
	elif v[2] < 9:
		v[2] += 1

	if v[1] == 9 and v[2] == 0:
		v[0] += 1
		v[1] = 0
		v[2] = 0
	elif v[1] < 9 and v[2] != 0:
		None
	elif v[1] < 9 and v[2] == 0:
		v[1] += 1

	return v

# -- Run the update

update()








