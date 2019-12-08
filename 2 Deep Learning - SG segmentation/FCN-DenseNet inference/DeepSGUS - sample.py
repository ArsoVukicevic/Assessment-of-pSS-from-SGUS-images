# Script for the automatic semantic segmentation of SGUS images

# https://github.com/sebastianbeyer/concavehull/blob/master/ConcaveHull.py

from DeepSGUS import DeepSGUS_CNN
import matplotlib.pyplot as plt
import cv2 as cv # Version 3.7
import numpy as np 
import tensorflow  as tf

print(tf.__version__) # 1.14.0
print(cv.__version__) # 4.1.0

#LOAD PRETRAINED MODEL
DeepSGUS = DeepSGUS_CNN('frozen_graph.pb')
DeepSGUS.print_layerNames()

#INPUTS 
inputImg    = 'IMG-0001-00008.jpg'
inputImg    = 'TIONI_0001_img.jpg'
inputImg    = 'STELLIN_0001_img.jpg'

#RUN SEGMENTATION
rez, output_BlackAndWhiteSG, output_contourSG, output_contourSG_points = DeepSGUS.segmentImage('in/' + inputImg)

#SAVE
cv.imwrite('out/' + inputImg + '_SG_predictions.jpg'   , rez) 
cv.imwrite('out/' + inputImg + '_SG_Black&White.jpg'   , output_BlackAndWhiteSG) 
cv.imwrite('out/' + inputImg + '_SG_Contour.jpg'       , output_contourSG) 
np.savetxt('out/' + inputImg + '_SG_Contour_Points.txt', output_contourSG_points) 

#SHOW
img = cv.imread('in/' + inputImg)
img = cv.cvtColor(img, cv.COLOR_BGR2RGB)
plt.imshow(img)
plt.plot(output_contourSG_points[:,0], output_contourSG_points[:,1])
plt.show()