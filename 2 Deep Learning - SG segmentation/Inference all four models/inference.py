import tensorflow as tf
import numpy as np
import datetime

import utils

import cv2
from time import sleep
import glob, os

from multiprocessing import Process, Queue

import tkinter as tk
from tkinter import *
from PIL import Image, ImageTk
import time

FLAGS = tf.flags.FLAGS
tf.flags.DEFINE_string('inference_graph_path', "./inference_graph/frozen_graph.pb", "Path to inference graph to be imported")
tf.flags.DEFINE_string("test_dir_input", "data_test/images/", "path to test images directory")
tf.flags.DEFINE_string("test_dir_output", "data_test/predictions/", "path to test images predictions")
tf.flags.DEFINE_string('mode', "test", "Mode: stream / video/ test")
tf.flags.DEFINE_integer('num_of_classes', 2, "Number of classes")
tf.flags.DEFINE_integer('input_size', 224, "Input image size")
tf.flags.DEFINE_boolean('resize_image', False, "Whether to resize input image and store resized one as the output")
tf.flags.DEFINE_integer('image_width', 640, "image height")
tf.flags.DEFINE_integer('image_height', 480, "image width")
tf.flags.DEFINE_boolean('display_fps', False, "Display frame per second")
tf.flags.DEFINE_string("path_to_video_input", "test.mp4", "path to the input video file")
tf.flags.DEFINE_string("path_to_video_output", "predicted.mp4", "path to the output video file")

dir_path = os.path.dirname(os.path.realpath(__file__))

def run_inference(q_in, q_cam, q_pred):
    print("Starting infrence process...") 

    if tf.gfile.Exists(FLAGS.inference_graph_path):
        print('Frozen graph file found: %s'%FLAGS.inference_graph_path)
    else:
        raise Exception('Frozen graph file not found: %s'%FLAGS.inference_graph_path)

    with tf.gfile.GFile(name=FLAGS.inference_graph_path,mode='rb') as f:
        input_graph_def = tf.GraphDef()
        input_graph_def.ParseFromString(f.read())

    graph = tf.get_default_graph()

    with tf.Session() as sess:
        print("Importing graph...")
        tf.import_graph_def(input_graph_def,name='import')

        image = graph.get_tensor_by_name('import/input_image:0')
        keep_probability = graph.get_tensor_by_name('import/keep_probabilty:0')
        TRAINING = graph.get_tensor_by_name('import/TRAINING:0')
        pred_annotation = graph.get_tensor_by_name('import/inference/prediction:0')
        
        frame_count = 0
        time_FPS = 3
        frame_rate = None
        start_time = time.time()

        while(True):
            while q_in.empty():
                sleep(0.03)
            
            frame_count += 1
            if time.time() - start_time > time_FPS:
                frame_rate = round(frame_count/time_FPS)
                start_time = time.time()
                frame_count = 0

            if FLAGS.mode == "stream":
                frame = [q_in.get() for _ in range(q_in.qsize())][-1]
            elif FLAGS.mode in ["video", "test"]:
                frame = q_in.get()

            frame_RGB = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            frame_RGB = cv2.resize(frame_RGB,(FLAGS.input_size,FLAGS.input_size))
            frame_RGB = frame_RGB.reshape(1,frame_RGB.shape[0],frame_RGB.shape[1],frame_RGB.shape[2])
            pred = sess.run(pred_annotation, feed_dict={image: frame_RGB, keep_probability: 1.0, TRAINING: False})
            final_mask_pred = utils.get_final_mask(pred[0],frame,FLAGS.num_of_classes)

            # Postprocess results
            if FLAGS.display_fps and frame_rate is not None:
                utils.add_overlays(final_mask_pred,frame_rate)
            
            q_pred.put(final_mask_pred)
            q_cam.put(frame)

    
def run_gui(q_cam, q_pred):
    print("Starting gui process...")    
    
    #Set up GUI
    window = tk.Tk()  #Makes main window
    window.wm_title("OVERSCENE")
    window.config(background="#FFFFFF")

    #Graphics window
    imageFrame = tk.Frame(window, width=600, height=500)
    imageFrame.grid(row=0, column=0, padx=10, pady=2)

    def show_frame():        

        while q_cam.empty():
            sleep(0.03)
#         frame_entrance = q_entrance.get(block=True)
        frame_cam = [q_cam.get() for _ in range(q_cam.qsize())][-1]
        cv2image_cam = cv2.cvtColor(frame_cam, cv2.COLOR_BGR2RGBA)
        img_cam = Image.fromarray(cv2image_cam)
        imgtk_cam = ImageTk.PhotoImage(image=img_cam)
        display1.imgtk = imgtk_cam #Shows frame for display 1
        display1.configure(image=imgtk_cam)
        
        while q_pred.empty():
            sleep(0.03)
#         frame_entrance = q_entrance.get(block=True)
        frame_pred = [q_pred.get() for _ in range(q_pred.qsize())][-1]
        cv2image_pred = cv2.cvtColor(frame_pred, cv2.COLOR_BGR2RGBA)
        img_pred = Image.fromarray(cv2image_pred)
        imgtk_pred = ImageTk.PhotoImage(image=img_pred)
        display2.imgtk = imgtk_pred #Shows frame for display 2
        display2.configure(image=imgtk_pred)
        
        window.after(1, show_frame) 

    display1 = tk.Label(imageFrame)
    display1.grid(row=0, column=0, padx=10, pady=20)  #Display 1 - camera
    
    display2 = tk.Label(imageFrame)
    display2.grid(row=0, column=1, padx=10, pady=20)  #Display 2 - mask

    show_frame() #Display
    window.mainloop()  #Starts GUI


def main(argv=None):

    q_in = Queue()
    q_cam = Queue()
    q_pred = Queue()

    processes = []
    p_inference = Process(target=run_inference, args=(q_in,q_cam,q_pred))
    p_gui = Process(target=run_gui, args=(q_cam,q_pred))

    if FLAGS.mode == "stream":
        p_inference.start()
        processes.append(p_inference)

        p_gui.start()
        processes.append(p_gui)

        cap = cv2.VideoCapture(0)

        while(True):
            # Capture frame-by-frame
            _, frame = cap.read()
            if FLAGS.resize_image:
                frame = cv2.resize(frame,(FLAGS.image_width,FLAGS.image_height))
            q_in.put(frame)

        cap.release()
        cv2.destroyAllWindows()

        for p in processes:
            p.join()
    
    elif FLAGS.mode=='video':
        
        video_path = os.path.join(dir_path,FLAGS.path_to_video_input)
        if not os.path.exists(video_path):
            raise Exception("Error: unable to find video on provided path - %s"%FLAGS.path_to_video_input)

        p_inference.start()
        processes.append(p_inference)
        
        cap = cv2.VideoCapture(FLAGS.path_to_video_input)

        total_frames = cap.get(cv2.CAP_PROP_FRAME_COUNT)
        video_fps = cap.get(cv2.CAP_PROP_FPS)
        print('Input video FPS: %d'%video_fps)

        fourcc = cv2.VideoWriter_fourcc(*'DIVX')
        if FLAGS.resize_image:
            out_video = cv2.VideoWriter(os.path.join(dir_path,FLAGS.path_to_video_output), 
                                        fourcc, video_fps, 
                                        (FLAGS.image_width, FLAGS.image_height))
        else:
            image_width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
            image_height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
            out_video = cv2.VideoWriter(os.path.join(dir_path,FLAGS.path_to_video_output), 
                            fourcc, video_fps, 
                            (image_width, image_height))

        frames_processed = 0
        time_start = time.time()
        while(cap.isOpened()):
            ret, frame = cap.read()

            if ret:
                if FLAGS.resize_image:
                    frame = cv2.resize(frame,(FLAGS.image_width,FLAGS.image_height))
                q_in.put(frame)
                time_start = time.time()
            elif time.time()-time_start > 5:
                break

            while q_in.qsize()>100:
                sleep(0.2)
            
            if not q_pred.empty():   
                frames_processed += 1
                pred = q_pred.get()
                out_video.write(pred)
                print('Progress: %f %%'%(100*frames_processed/total_frames))

        out_video.release()


    elif FLAGS.mode == "test":
        print('Loading test images...')
        test_images_orig, file_names = utils.readTestData(FLAGS.test_dir_input,FLAGS.input_size)
        
        p_inference.start()
        processes.append(p_inference)

        for i in range(len(file_names)):
            image = test_images_orig[i]
            fname = file_names[i]

            if FLAGS.resize_image:
                image = cv2.resize(image,(FLAGS.image_width,FLAGS.image_height))

            q_in.put(image)
            pred = q_pred.get(block=True)
            cv2.imwrite(os.path.join(FLAGS.test_dir_output,fname) + '.png' ,pred)
            print('Image processed: %s'%fname)

    else:
        raise Exception('Error: unknown value for argument mode')

    for p in processes:
        p.terminate()


if __name__ == "__main__":
    tf.app.run()
