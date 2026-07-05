**Autonomous Racing Car Environment**

An autonomous racing car environment built using the Godot Engine and trained using Deep Reinforcement Learning. The models are trained to navigate a track using Proximal Policy Optimization (PPO).

Technical Specifications

* Engine: Godot Engine
* RL Framework: Stable Baselines3 (SB3)
* Algorithm: Proximal Policy Optimization (PPO)
* Integration: Godot RL Agents Plugin

Repository & File Structure

Because the compiled game environments are large, they are not stored directly in the source code. You will need to download them separately from the **Releases** tab.

Your local repository should look exactly like this before running the tests:

```
racing-car-rl/
├── executables/               # You must create this folder and add the release files here
│   ├── racing-env.exe         # Windows environment (Download from Releases)
│   └── racing-env.x86_64      # Linux environment (Download from Releases)
├── models/
│   ├── model1.zip             # Trained SB3 model
│   └── model2.zip             # Trained SB3 model
├── test_models.py             # Main testing script
├── .gitignore
└── README.md

```

Setup Instructions

To run the models on your local machine, follow these exact steps:

1. Clone the repository

```
git clone https://github.com/your-username/racing-car-rl.git
cd racing-car-rl

```

2. Install Python Dependencies
Ensure you have Python installed, then install the required libraries:

```
pip install stable-baselines3 godot-rl

```

3. Download the Executables

1. Go to the **Releases** section on the right side of this GitHub repository page.
2. Download the latest `.zip` file containing the compiled executables.
3. Extract the contents and place `racing-env.exe` (Windows) or `racing-env.x86_64` (Linux) into a folder named `executables/` in the root directory of this project.

How to Test the Models

Once the executables are in place, you can watch the trained models drive the car by running the testing script from your terminal:

```
python test_models.py

```

The script is fully interactive. When prompted in the terminal:

1. **Enter model version (1 or 2):** Select which model brain you want to test.
2. **Select your OS (1 or 2):** Enter `1` for Linux or `2` for Windows to launch the correct environment file.

A Godot window will open automatically, and the car will begin navigating the track autonomously based on the model's predictions.

## Model Briefs

### Model 1:

* Deprecated / Experimental
* Description: This model was trained on an older iteration of the reward system. During training, the agent discovered a mathematical loophole in the reward logic: instead of navigating the track,
  it realized it could maximize its score by simply driving straight into a wall and sticking to it. It is kept in the repository as a classic example of reward hacking in reinforcement learning.

### Model 2: 

* Working
* Training Time: ~900,000 steps
* Description: This is the first successfully trained model using an updated and balanced reward system. It is capable of driving autonomously around the track and keeping the vehicle on the road for
  the majority of the environment. However, it still struggles with extreme braking and tends to get stuck on particularly sharp corners.
