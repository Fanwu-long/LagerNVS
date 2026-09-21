import os
import glob
import shutil
import subprocess
DATA = "/home/scc/pb25612046/data_eval/re10k/test/images"
OUT = "/home/scc/pb25612046/lagernvs/outputs/showcase512"
PY = "/home/scc/pb25612046/.conda/envs/lagernvs/bin/python"
CWD = "/home/scc/pb25612046/lagernvs"
os.makedirs(OUT, exist_ok=True)
scenes = [
    "e9670b30a2c0e348",
    "cdf439b17a6a98d4",
    "ee9503a872caad73",
    "59636f39d067119d",
    "45a00d135c5388fc",
]
def pick_views(scene, k):
    fs = sorted(glob.glob(os.path.join(DATA, scene, "*.png")))
    n = len(fs)
    if n == 0:
        return None
    if k >= n:
        return fs
    idx = [int(round(i * (n - 1) / (k - 1))) for i in range(k)]
    return [fs[i] for i in idx]
tasks = []
for i, scene in enumerate(scenes):
    tasks.append((scene, 6))
    if i < 2:
        tasks.append((scene, 2))
for scene, k in tasks:
    out = os.path.join(OUT, scene + "_" + str(k) + "v_100f.mp4")
    if os.path.exists(out) and os.path.getsize(out) > 100000:
        print("SKIP existing", out, flush=True)
        continue
    imgs = pick_views(scene, k)
    if not imgs:
        print("MISSING scene", scene, flush=True)
        continue
    indir = os.path.join(OUT, scene + "_inputs")
    os.makedirs(indir, exist_ok=True)
    for im in imgs:
        shutil.copy2(im, os.path.join(indir, "in_" + str(k) + "v_" + os.path.basename(im)))
    print("=== ", scene, k, "views ===", flush=True)
    r = subprocess.run(
        [PY, "minimal_inference.py", "--images"] + imgs
        + ["--video_length", "100", "--output", out],
        cwd=CWD,
    )
    print("exit=", r.returncode, flush=True)
print("SHOWCASE_ALL_DONE", flush=True)
