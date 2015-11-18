import os;


#Written by Ryan Dsouza
#Quickly renames all the photos in a directory with the format
#'Screenshot_X.png', where X is that file's place in the directory

#Also prints out the markdown code to display these many images

#Run instructions: 'python ImageRenamer.py'


files = os.listdir('.');
index = 0;

projectName = "iMessageAnalyzer"

prefix = "https://github.com/dsouzarc/" + projectName + "/blob/master/Screenshots/";

for fileName in sorted(files):

    if fileName != "ImageRenamer.py":

        if "Screenshot_" in fileName:
            index += 1;

for fileName in sorted(files):
        if "Screenshot_" not in fileName and fileName != "ImageRenamer.py":
            newFileName = "Screenshot_" + str(index) + ".png";
            os.rename(fileName, newFileName);
            print("![Screenshot " + str(index) + "](" + prefix + newFileName + ")");
            index += 1;

