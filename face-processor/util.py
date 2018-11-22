#!/usr/bin/env python
# coding: utf-8


# Example python util.py --image photo.jpg  --output currentoutput.png

# %pylab inline
import scipy
import numpy as np
import dlib
import cv2
import argparse

import os 
dir_path = os.path.dirname(os.path.realpath(__file__))

def shape_to_np(shape, dtype="int"):
	coords = np.zeros((68, 2), dtype=dtype)
	for i in range(0, 68):
		coords[i] = (shape.part(i).x, shape.part(i).y)
    # return the list of (x, y)-coordinates
	return coords

ap = argparse.ArgumentParser()
ap.add_argument("-i", "--input", required=True,
	help="path to input image")
ap.add_argument("-o", "--output", required=True,
	help="path to output image")
args = vars(ap.parse_args())


# In[56]:


detector = dlib.get_frontal_face_detector()
predictor = dlib.shape_predictor(dir_path + "/shape_predictor_68.dat")


# In[3]:


# load the input image, resize it, and convert it to grayscale
image = cv2.imread(args["input"])
#image = imutils.resize(image, width=500)
gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
 
# detect faces in the grayscale image
rects = detector(gray, 1)


# In[4]:


#imshow(gray)


# In[5]:


shape = predictor(gray, rects[0])
shape = shape_to_np(shape)


# In[6]:


mouth=shape[48:68]


# In[7]:


left=min(mouth[:,0])
right=max(mouth[:,0])
top=min(mouth[:,1])
bot=max(mouth[:,1])
padd = int((bot-top)*0.5)


# In[8]:


# myrect =newgray
# myrect = cv2.rectangle(myrect, (left-padd,top-padd), (right+padd,bot+padd), (0,255,0), 5)
# imshow(myrect)


# In[9]:


g1 = image.copy()
sly,slx = slice(left-padd ,right+padd), slice(top-padd,bot+padd)
g1[slx, sly] = g1[slx,sly][::-1, :]
# imshow(g1)


# In[64]:


cv2.imwrite(args["output"],g1)


# In[ ]:




