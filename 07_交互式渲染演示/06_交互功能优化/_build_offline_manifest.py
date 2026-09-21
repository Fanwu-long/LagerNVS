# -*- coding: utf-8 -*-
"""Rebuild offline_manifest.json — curated for visual quality.

Drops heavily fogged/low-detail orbit clips (package encode + model limits).
Never prefers *_up.mp4 as primary (upscale often adds mosaic).
"""
from __future__ import annotations

import json
import os
from pathlib import Path

OPT = Path(__file__).resolve().parent
DEMO = OPT.parent
PROJECT = DEMO.parent

# Mid-frame Laplacian variance thresholds (measured on this package).
# Soft orbits look fogged / mosaicked in the player — exclude from default list.
ORBIT_MIN_SHARPNESS = 5.0
# Prefer these when present (already measured sharp enough).
ORBIT_KEEP = {
    "scenea_2v": 167.0,
    "scenea_4v": 7.2,
    "3a3bc11b9ebb7d44_00017": 16.2,
    "2c9018ef57c6b061_00019": 15.0,
    "45a00d135c5388fc_00012": 9.3,
}
# Known soft — keep out of default curated list.
ORBIT_DROP = {
    "demo",
    "59636f39d067119d_00000",
    "189f95593df3c7f1_00004",
    "4a763e1b87e495a7_00024",
    "0f2197967bb7fa43_00022",
    "357ddf77c7b83cae_00004",
}


def by_prefix(root: Path) -> dict[str, Path]:
    out: dict[str, Path] = {}
    for d in root.iterdir():
        if d.is_dir() and len(d.name) >= 2 and d.name[:2].isdigit():
            out[d.name[:2]] = d
    return out


def rel(p: Path) -> str:
    return Path(os.path.relpath(p, PROJECT)).as_posix()


def exists(p: Path | None) -> bool:
    return bool(p and p.exists() and p.stat().st_size > 0)


def pick_orbit(d03: Path, stem: str) -> tuple[Path | None, Path | None]:
    """Return (primary, alt). Prefer native over *_up to avoid upscale mosaic."""
    native = d03 / f"orbit_{stem}.mp4"
    up = d03 / f"orbit_{stem}_up.mp4"
    if exists(native):
        return native, up if exists(up) else None
    if exists(up):
        return up, None
    return None, None


def main() -> None:
    dirs = by_prefix(DEMO)
    d01, d02, d03, d04 = dirs["01"], dirs["02"], dirs["03"], dirs["04"]
    final = PROJECT / "03_最终成果包" / "lagernvs_final"
    scenes: list[dict] = []

    compare_dir = final / "02_top20_gt_pred"
    input_root = final / "07_input_views"
    hq_ids = [
        ("eae986c8f31081cc_00051", "eae986c8f31081cc_inputs", "HQ · GT|Pred（推荐先看静帧）"),
        ("e9670b30a2c0e348_00001", "e9670b30a2c0e348_inputs", "HQ · 边缘较清晰 · GT|Pred"),
        ("fbcd62ab8ff30b4f_00013", None, "HQ · GT|Pred"),
        ("45a00d135c5388fc_00012", "45a00d135c5388fc_inputs", "HQ · living room · GT|Pred"),
        ("c1ad4232258e87c9_00014", None, "HQ · GT|Pred"),
    ]
    for cid, inp_name, note in hq_ids:
        cmp = compare_dir / f"COMPARE_{cid}.png"
        if not exists(cmp):
            print("skip missing still", cid)
            continue
        inputs = []
        if inp_name:
            folder = input_root / inp_name
            if folder.exists():
                inputs = [rel(p) for p in sorted(folder.glob("in_*.png")) if exists(p)][:6]
        # Only attach orbit if it is in the sharp keep-list
        video = video_alt = None
        if cid in ORBIT_KEEP:
            prim, alt = pick_orbit(d03, cid)
            if prim:
                video, video_alt = rel(prim), rel(alt) if alt else None
        scenes.append(
            {
                "id": f"hq_{cid}",
                "title": cid,
                "group": "1 · HQ 静帧（清晰）",
                "mode": "still",
                "still": rel(cmp),
                "video": video,
                "video_alt": video_alt,
                "path_video": None,
                "inputs": inputs,
                "note": note + (f" · {len(inputs)} inputs" if inputs else ""),
                "quality": "hq",
                "w": 512,
                "h": 1090,
            }
        )

    sa_inputs = []
    for name in ["v1.jpg", "v2.jpg", "v3.jpg", "v4.jpg"]:
        p = d01 / "scene_a" / name
        if exists(p):
            sa_inputs.append(rel(p))

    # Sharpest orbit first
    if exists(d03 / "orbit_scenea_2v.mp4"):
        scenes.append(
            {
                "id": "scenea_2v",
                "title": "scene_a · 2 views（最清晰轨道）",
                "group": "2 · Orbit（已筛软糊）",
                "mode": "video",
                "still": None,
                "video": rel(d03 / "orbit_scenea_2v.mp4"),
                "video_alt": None,
                "path_video": rel(d04 / "scenea_2v_240f.mp4") if exists(d04 / "scenea_2v_240f.mp4") else None,
                "inputs": sa_inputs[:2],
                "note": "包内码率最高 · 优先演示",
                "quality": "good",
                "w": 640,
                "h": 408,
            }
        )

    # scenea_4v: use native (avoid upscale mosaic); keep _up as alt
    if exists(d03 / "orbit_scenea_4v.mp4"):
        scenes.append(
            {
                "id": "scenea_4v",
                "title": "scene_a · 4 views",
                "group": "2 · Orbit（已筛软糊）",
                "mode": "video",
                "still": None,
                "video": rel(d03 / "orbit_scenea_4v.mp4"),
                "video_alt": rel(d03 / "orbit_scenea_4v_up.mp4")
                if exists(d03 / "orbit_scenea_4v_up.mp4")
                else None,
                "path_video": rel(d04 / "scenea_4v_240f.mp4") if exists(d04 / "scenea_4v_240f.mp4") else None,
                "inputs": sa_inputs,
                "note": f"4 inputs · 原生编码（非放大）",
                "quality": "ok",
                "w": 640,
                "h": 584,
            }
        )

    for sid in [
        "3a3bc11b9ebb7d44_00017",
        "2c9018ef57c6b061_00019",
        "45a00d135c5388fc_00012",
    ]:
        prim, alt = pick_orbit(d03, sid)
        if not prim:
            print("skip missing orbit", sid)
            continue
        inp_dir = d02 / sid
        inputs = (
            [rel(p) for p in sorted(inp_dir.glob("input_*.png")) if exists(p)]
            if inp_dir.exists()
            else []
        )
        scenes.append(
            {
                "id": sid,
                "title": sid,
                "group": "2 · Orbit（已筛软糊）",
                "mode": "video",
                "still": None,
                "video": rel(prim),
                "video_alt": rel(alt) if alt else None,
                "path_video": None,
                "inputs": inputs,
                "note": f"清晰度合格 · {len(inputs)} inputs",
                "quality": "ok",
                "w": 640,
                "h": 640,
            }
        )

    # Intentionally omit ORBIT_DROP (demo + soft DL3DV) — fog/mosaic too severe for showcase.
    for dropped in sorted(ORBIT_DROP):
        print("curated-out soft orbit:", dropped)

    scenes = [s for s in scenes if s.get("still") or s.get("video")]

    page = Path(os.path.relpath(OPT / "offline_orbit_viewer.html", PROJECT)).as_posix()
    n_still = sum(1 for s in scenes if s.get("still"))
    n_orbit = sum(1 for s in scenes if s.get("video") and not s.get("still"))
    n_inputs = sum(len(s.get("inputs") or []) for s in scenes)
    manifest = {
        "title": "Interactive demo",
        "subtitle": (
            f"已按清晰度筛选 · {len(scenes)} 场景 · {n_still} HQ 静帧 · "
            f"{n_orbit} 合格轨道（已移除严重雾化/马赛克条目）"
        ),
        "page": page,
        "quality_note": (
            "雾化/残影主要来自 LagerNVS 对未充分观测区域的预测，不是播放器损坏。"
            "请优先看「HQ 静帧」；Orbit 仅为相机轨迹示意。"
        ),
        "stats": {
            "scenes": len(scenes),
            "hq_stills": n_still,
            "orbit_clips": sum(1 for s in scenes if s.get("video")),
            "input_thumbs": n_inputs,
            "dropped_soft_orbits": sorted(ORBIT_DROP),
        },
        "scenes": scenes,
    }
    text = json.dumps(manifest, ensure_ascii=False, indent=2)
    for out in (OPT / "offline_manifest.json", PROJECT / "offline_manifest.json", DEMO / "offline_manifest.json"):
        out.write_text(text, encoding="utf-8")
    print(f"scenes={len(scenes)} stills={n_still} orbits={sum(1 for s in scenes if s.get('video'))} inputs={n_inputs}")


if __name__ == "__main__":
    main()
