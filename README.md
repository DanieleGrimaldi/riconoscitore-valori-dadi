# 🎲 Dice Score Recognizer - Classical Computer Vision Pipeline

> **⚠️ Note to Recruiters & Engineers:** 
> This project was developed as a final assignment for the "Image Processing" course. It was built under strict academic constraints: **the use of pre-trained Deep Learning models (e.g., CNNs, YOLO) was explicitly forbidden**. 
> The entire pipeline—from motion detection to digit classification—relies exclusively on **classical Computer Vision techniques, mathematical morphology, and traditional Machine Learning algorithms** built from scratch.

## 📌 Project Overview
The goal of this application is to analyze a video feed of dice rolls and automatically calculate the total score of each valid roll. The system handles variable illumination, reflections, and overlapping dice by executing a multi-stage classical computer vision pipeline.

## ⚙️ Architecture & Processing Pipeline

The system is structured into three main independent modules:

### 1. Motion Detection & Frame Extraction
To process only stable frames (when the dice stop rolling), the system analyzes the video feed using:
*   **Background Subtraction & Frame Differencing:** Continuously calculates the Euclidean distance between consecutive frames.
*   **Stability Counters:** A frame is locked for processing only when the movement threshold remains at `0` for a consecutive number of frames (e.g., `stableCount = 17`).

### 2. Dice Segmentation & Separation
To isolate the dice from the background tray, we implemented a pixel-wise classification approach:
*   **Feature Extraction:** Extracted 4 distinct channels for each pixel: `L`, `a`, `b` (from the CIELAB color space) and `Texture` (local standard deviation).
*   **Decision Tree Classifier:** A model trained on a balanced dataset (max 100,000 background pixels) to generate a binary mask of candidate components.
*   **Geometric Separation:** Applied mathematical morphology and blob management algorithms to physically separate dice that are touching each other.

### 3. Digit Extraction & Classification (Core Contribution)
Once the single die is isolated, the digit (score) is extracted and decoded:
*   **DBSCAN Clustering:** Instead of simple thresholding, we applied a customized DBSCAN algorithm (`min_pts = 5`, `epsilon = [0.10, 0.3]`) working on spatial and color features `[L, a, b, 2x, 2y]` to cluster the digit pixels
*   **Morphological Filtering:** Median filters and quantization to clean the extracted clusters and select the most central valid area (area between 70 and 500 px).
*   **Feature Engineering (Shape Descriptors):** Extracted 6 invariant shape descriptors for each digit: *Circularity, Euler Number, Eccentricity, Solidity*, and the *First two Hu Moments in logarithmic scale*
*   **k-NN Classification:** The extracted feature vector is fed into a *k-Nearest Neighbors* ($k=3$, standardized) classifier trained on a balanced dataset to predict the final digit.

## 📊 Performance Metrics

Despite the absence of Deep Learning, the classical pipeline achieved solid results on the test sets:
*   **Dice Mask Extraction (Decision Tree):** `99.75%` Accuracy | `0.85` IoU | `93.41%` Recall.
*   **Digit Classification (k-NN):** `80.8%` Accuracy on Training Set | `62.5%` Accuracy on complex Test Sets.

## 🛠️ Tech Stack
*   **Language:** MATLAB
*   **Libraries:** Image Processing Toolbox, Statistics and Machine Learning Toolbox

## 👥 Role & Code Ownership
While this was officially a university group assignment, I served as the **Project Lead and Core Developer**. I personally designed the overall software architecture and single-handedly implemented the core algorithmic modules, including the DBSCAN clustering logic, the geometric feature extraction pipeline (Hu Moments), and the k-NN classification training.

