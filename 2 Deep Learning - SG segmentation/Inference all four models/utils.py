import cv2
import glob, os
import numpy as np 

def readTestData(test_dir_path,resize_size):
    file_paths = glob.glob(test_dir_path + "*.png")
    file_paths.extend(glob.glob(test_dir_path + "*.jpg"))
    
    test_images_orig = np.array([transform(file_path,False) for file_path in file_paths])
    
    file_names = [file_path.split('/')[-1].replace('.png','').replace('.jpg','') for file_path in file_paths]

    return test_images_orig, file_names
    
def transform(file_path, resize, resize_size=None):
    image = cv2.imread(file_path)

    if resize:
        image = cv2.resize(image,(resize_size, resize_size))

    return np.array(image)


def get_final_mask(pred,src,NUM_OF_CLASSESS):

    np.random.seed(111)
    final_mask = np.zeros(shape=src.shape,dtype=np.uint8)
    
    for i in range(1,NUM_OF_CLASSESS):
        color = np.random.randint(0,255,3)

        mask_boolean = (pred==i)*1         
        mask_boolean = mask_boolean.astype(np.uint8)

        mask = np.zeros((mask_boolean.shape[0],mask_boolean.shape[1],3), src.dtype)
        mask[:,:] = color
        mask = cv2.bitwise_and(mask, mask, mask=mask_boolean)
        mask = cv2.resize(mask,(src.shape[1],src.shape[0]))  

        final_mask = cv2.addWeighted(mask, 1.0, final_mask, 1.0, 0)

    final_mask = cv2.addWeighted(final_mask, 2.0, src, 0.7, 0)

    return final_mask


def add_overlays(frame, frame_rate):
    cv2.putText(frame, "FPS: " + str(frame_rate), (10, 20),
                cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 0, 0),
                thickness=2, lineType=2)
    
