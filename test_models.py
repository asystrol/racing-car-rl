from stable_baselines3 import PPO
from godot_rl.wrappers.stable_baselines_wrapper import StableBaselinesGodotEnv

model_v = input("enter model version (enter 1 or 2)")
print("1) Linux")
print("2) Windows")
os = input("which os are you using? (enter 1 or 2)")

model_v = model_v.strip()
os = os.strip()

if os == "1":
    env = StableBaselinesGodotEnv(env_path="executables/racing-env.x86_64", port=10008, show_window = True)
elif os == "2":
    env = StableBaselinesGodotEnv(env_path="executables/racing-env.exe", port=10008, show_window = True)

model_path = "models/model"+model_v+".zip"
model = PPO.load(model_path, env=env)

obs = env.reset()
for i in range(1000):
    action, _states = model.predict(obs, deterministic=True)
    obs, reward, done, info = env.step(action)
    
    if done:
        obs = env.reset()

print("Testing complete.")
env.close()