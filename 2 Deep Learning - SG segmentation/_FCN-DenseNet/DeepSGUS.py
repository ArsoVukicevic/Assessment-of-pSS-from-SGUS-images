# Script for the automatic semantic segmentation of SGUS images

#libraries
import tensorflow as tf  
import numpy as np 
import cv2 as cv
import os
import matplotlib.pyplot as plt
import pickle
import time
import imutils

class DeepSGUS_CNN(object):

    def __init__(self, model_filepath='frozen_graph.pb', inputSize = 224):
        self.input_size = inputSize
        self.graph      = None
        # The file path of model
        self.model_filepath = model_filepath
        # Initialize the model
        self.load_graph(model_filepath = self.model_filepath)

    #Load pretrained model
    #INPUTS
        #model_filepath - path to pb file 
    #OUTPUT
        #updated self/object
    def load_graph(self, model_filepath):
        tf.reset_default_graph()
        print('Loading model...')
        self.graph = tf.get_default_graph()
        self.sess  = tf.InteractiveSession(graph = self.graph)

        with tf.gfile.GFile(model_filepath, 'rb') as f:
            self.graph_def = tf.GraphDef()
            self.graph_def.ParseFromString(f.read())

        print('Check out the input placeholders:')
        nodes = [n.name + ' => ' +  n.op for n in self.graph_def.node if n.op in ('Placeholder')]
        for node in nodes:
            print(node)
        #Import the frozen graph
        tf.import_graph_def(self.graph_def,name='import')
        #Input placeholders
        self.input_image         = self.graph.get_tensor_by_name('import/input_image:0')
        self.output_segmentation = self.graph.get_tensor_by_name('import/inference/prediction:0')    
        self.keep_probability    = self.graph.get_tensor_by_name('import/keep_probabilty:0')
        self.TRAINING            = self.graph.get_tensor_by_name('import/TRAINING:0')
        self.annotation          = tf.placeholder(dtype=tf.int32,shape=[None,self.input_size,self.input_size,1])
        print('Model loading complete!')
   
    # Print layers' names
    #INPUTS
        #none
    #OUTPUTS
        #none 
    def print_layerNames(self): 
        print('Composing layers:')
        if self.graph != None :
            layers = [op.name for op in self.graph.get_operations()]
            for layer in layers:
                print(layer)
        else:
            print("Graph is not loaded!")

    #Function for reading/adapting images for the TensorFlow graph
    #INPUT
        #img - numarray/filepat
    #OUTPUT
        #img        - loaded and resize image (with respoect to the self.input_size)
        #orgW, orgH - original width and height
        #orgImg     - original image
    def loadImage(self, img):
        #if img paramter is string
        if type(img) == str :
            #try to load it using OpenCV
            try:
                #Read file
                img = cv.imread(img)
                #Convert to RGB colorspace
                img = cv.cvtColor(img,cv.COLOR_BGR2RGB)
            except:
                #if reading file failed, print msg, return None
                print("Image " + img + " cannot be loaded, plase check.")
                return None, None, None
        orgW   = img.shape[1]
        orgH   = img.shape[0]
        orgImg = img
        #if input image is array, ensure that it dimensions match input of the CNN
        img =  cv.resize(img,(self.input_size, self.input_size))  
        #return results
        return img, orgW, orgH, orgImg

    # Inference on the input data (image)
    #INPUTS 
        #img    - image (string, or numpy opncv)
        #img_gt - ground truth image
    #OUTPTUS
        #output                  - output of the nework (per-pixel classification)
        #output_BlackAndWhiteSG  - image (white is SG, black is bacground)
        #output_contourSG        - image (resulting contour is drawn over input image)
        #output_contourSG_points - list of contour points
    def segmentImage(self, img):
        img, orgW, orgH, orgImg = self.loadImage(img)

        #Run CNN
        feed_dict={ self.input_image:np.expand_dims(img,0),\
                    self.keep_probability:1.0,\
                    self.TRAINING:False } 
        output = self.sess.run(self.output_segmentation, feed_dict)
        output = output[0]

        # Make bacground black and prediction white
        originalImage = output.astype(np.uint8)
        (thresh, output_BlackAndWhiteSG) = cv.threshold(originalImage, 0.5, 255, cv.THRESH_BINARY)

        # Detect contours
        edged = cv.Canny(output_BlackAndWhiteSG, 0.15, 1)
        cnts  = cv.findContours(edged.copy(), cv.RETR_TREE, cv.CHAIN_APPROX_NONE)
        cnts  = imutils.grab_contours(cnts)
        
        # Draw contours
        output_contourSG        = orgImg
        output_contourSG_points = list()
        for cnt in cnts:
            for i in range(0, len(cnt)):
                cnt[i][0][0] = cnt[i][0][0]  * (orgW/self.input_size)
                cnt[i][0][1] = cnt[i][0][1]  * (orgH/self.input_size)
                output_contourSG_points.append((cnt[i][0][0],cnt[i][0][1]))
            cv.polylines(output_contourSG,[cnt],True,(0,255,255), 5) 
        from ConcaveHull  import concaveHull
        output_contourSG_points = concaveHull(np.asarray(output_contourSG_points), 5)

        output                 = cv.resize(originalImage,(orgW, orgH)) 
        output_BlackAndWhiteSG = cv.resize(output_BlackAndWhiteSG,(orgW, orgH))  
        # return results
        return output, output_BlackAndWhiteSG, output_contourSG, output_contourSG_points