# Attention Management Scoring — Calculation Guide

## Purpose

This document explains how the Attention Minder application:

1. Decides whether a user is attentive.
2. Calculates the management-session score.
3. Calculates the metrics sent to the backend.
4. Calculates the values shown on the management result screen.

The central idea is simple: each analyzed camera frame is treated as one observation. An observation is classified as either **attentive** or **inattentive**.

---

## 1. Frame classification

A frame is classified as attentive only when all required conditions are satisfied:

- The user's face is visible.
- The lighting is sufficient.
- Both eyes are open.
- The user is not yawning.
- The user's eyes and head are directed toward the screen.

In simplified form:

```text
Attentive =
    face visible
    AND lighting acceptable
    AND eyes open
    AND not yawning
    AND gaze/head direction centered
```

If any confirmed attention problem is present, the frame is classified as inattentive. These problems include:

- Face missing
- Low light
- Both eyes closed
- One eye closed for too long
- Yawning
- Looking left or right
- Looking up or down

---

## 2. Main score

### Attention Engagement Rate

The main calculation is:

```text
Attention Engagement Rate =
    Attentive Frames / Total Frames × 100
```

Example:

```text
Total frames     = 10
Attentive frames = 7

Attention Engagement Rate = 7 / 10 × 100 = 70%
```

### Final Score

The final score is the rounded Attention Engagement Rate, limited to the range 0–100:

```text
Final Score = clamp(round(Attention Engagement Rate), 0, 100)
```

Example:

```text
Attentive frames = 2
Total frames     = 3

Attention Engagement Rate = 2 / 3 × 100 = 66.666...%
Final Score              = round(66.666...) = 67
```

---

## 3. Inattention duration

The application normally analyzes one frame approximately every 500 milliseconds.

If the previous observation was inattentive, the time between it and the next observation is added to the inattention duration.

Example:

```text
0.0 seconds → inattentive
0.5 seconds → inattentive
1.0 seconds → inattentive
1.5 seconds → attentive

Total inattention = 0.5 + 0.5 + 0.5 = 1.5 seconds
```

The application records two values:

- **Total inattention duration:** all observed distraction periods added together.
- **Maximum inattention duration:** the longest single continuous distraction period.

### Camera-stall protection

If two observations are more than 1.6 seconds apart, the missing interval is not counted as inattention. This prevents a frozen camera or processing delay from unfairly reducing the user's score.

---

## 4. Backend request body

At the end of the session, the application sends a request similar to:

```json
{
  "file_id": 123,
  "is_assessment": false,
  "final_score": 70,
  "attention_engagement_rate": 70.0,
  "average_confidence": 0.91,
  "total_processed_frames": 100,
  "sampled_frames": 100,
  "session_duration_seconds": 60,
  "inattention_duration": 18.5,
  "gaze_ratio_avg": 0.82,
  "drowsy_state": 0.04,
  "brightness_score": 73.0,
  "pitch": 1.4,
  "yaw": -2.1,
  "roll": 0.8,
  "blink_ratio": 0.06,
  "yawn_distance": 0.12,
  "bad_frame_count": 30,
  "blurry_frame_count": 0,
  "low_light_frame_count": 4,
  "eyes_closed_count": 3,
  "gaze_warning_count": 2
}
```

### Field-by-field calculations

#### `file_id`

The identifier of the video watched during the session. It is not calculated.

#### `is_assessment`

- `true`: assessment session
- `false`: normal management treatment

#### `final_score`

```text
round(Attentive Frames / Total Frames × 100)
```

#### `attention_engagement_rate`

```text
Attentive Frames / Total Frames × 100
```

Unlike the final score, this value retains its decimal precision.

#### `average_confidence`

MediaPipe supplies a confidence value between 0 and 1 for usable iris and face information.

```text
Average Confidence =
    Sum of Confidence Values / Number of Confidence Samples
```

Example:

```text
(0.8 + 0.9 + 1.0) / 3 = 0.9
```

#### `total_processed_frames`

The number of camera frames completely analyzed by the attention monitor.

#### `sampled_frames`

The number of camera frames selected for analysis. Processed and sampled frame counts will normally be equal in the current implementation.

#### `session_duration_seconds`

```text
round(Latest Video Position in Milliseconds / 1000)
```

#### `inattention_duration`

The total observed time, in seconds, spent in an inattentive state.

```text
Total Inattention =
    Distraction Period 1 + Distraction Period 2 + ...
```

#### `gaze_ratio_avg`

This represents average gaze quality from 0 to 1:

- `1.0`: gaze is generally centered.
- `0.0`: gaze is generally far from the screen.

For each usable gaze sample:

```text
Horizontal Deviation =
    Absolute Horizontal Gaze Offset / Horizontal Threshold

Vertical Deviation =
    Absolute Vertical Gaze Offset / Vertical Threshold

Largest Deviation =
    max(Horizontal Deviation, Vertical Deviation)

Frame Gaze Quality =
    1 - clamp(Largest Deviation, 0, 1)
```

The session value is:

```text
Gaze Ratio Average =
    Sum of Frame Gaze Qualities / Gaze Sample Count
```

#### `drowsy_state`

```text
Drowsy State = Eyes-Closed Frames / Sampled Frames
```

This is a ratio rather than a percentage. For example, `0.05` represents 5%.

#### `brightness_score`

Every usable frame produces a mean luminance value between 0 and 1:

```text
Frame Brightness Score = Mean Luminance × 100

Session Brightness Score =
    Sum of Frame Brightness Scores / Brightness Sample Count
```

The result ranges from approximately 0 for completely dark to 100 for very bright.

#### `pitch`

The average up/down head angle across frames containing a face:

```text
Average Pitch = Sum of Pitch Angles / Valid Face Samples
```

#### `yaw`

The average left/right head-turn angle across frames containing a face:

```text
Average Yaw = Sum of Yaw Angles / Valid Face Samples
```

#### `roll`

The average sideways head-tilt angle across frames containing a face:

```text
Average Roll = Sum of Roll Angles / Valid Face Samples
```

#### `blink_ratio`

A normal blink is counted when both eyes remain closed for at least 100 milliseconds but less than 1,500 milliseconds.

```text
Blink Ratio = Blink Count / Sampled Frames
```

A closure of 1,500 milliseconds or longer is treated as a long eye closure rather than a normal blink.

#### `yawn_distance`

This field currently contains the session's average mouth-open ratio:

```text
Yawn Distance =
    Sum of Mouth-Open Ratios / Valid Mouth Samples
```

Despite its name, this field is not the number of yawns.

#### `bad_frame_count`

The number of analyzed frames whose final state was not focused:

```text
Bad Frame Count = Total Frames - Attentive Frames
```

#### `blurry_frame_count`

This is currently always `0` because blur detection is not connected to the scoring pipeline.

#### `low_light_frame_count`

The number of frames classified as confirmed low-light observations.

#### `eyes_closed_count`

The number of frames where both eyes were confirmed closed. Ordinary quick blinks are not automatically treated as sustained eye-closure events.

#### `gaze_warning_count`

The number of directional warning episodes. It increases when the user enters a confirmed looking-left, looking-right, looking-up, or looking-down state.

Ten consecutive frames belonging to the same looking-left episode count as one warning—not ten warnings. Returning to the center and later looking left again creates a second warning.

---

## 5. Management result screen

### Score

```text
Displayed Score = Final Score
```

### Performance level

| Score | Performance level |
|---:|---|
| 90–100 | Excellent |
| 70–89 | Good |
| 50–69 | Fair |
| 0–49 | Needs Improvement |

### Concentration

For local hybrid monitoring:

```text
Concentration = Attention Engagement Rate / 10
```

Example:

```text
Attention Engagement Rate = 76%
Concentration             = 76 / 10 = 7.6/10
```

### Face detection

```text
Face Detection Percentage =
    Frames Containing a Face / Sampled Frames × 100
```

### Attention

```text
Attention Percentage =
    Attentive Frames / Total Frames × 100
```

This is the same underlying value as `attention_engagement_rate`, rounded to a whole percentage for display.

### Progress

Progress is not calculated from camera observations. It comes from the backend completion response:

```text
progress_updated = true  → Updated
otherwise                → Pending
```

### Videos watched

The number of videos in the current treatment list.

### Duration

The latest known video playback position, formatted as time.

### Metrics

```text
Metrics = Sampled Frames
```

### Frames

```text
Frames = Total Processed Frames
```

### Maximum inattention

The longest single continuous distraction period:

```text
Maximum Inattention =
    max(Distraction Period 1, Distraction Period 2, ...)
```

---

## 6. Complete worked example

Assume the application analyzes ten frames:

```text
Frame 1  → Focused
Frame 2  → Focused
Frame 3  → Focused
Frame 4  → Looking left
Frame 5  → Looking left
Frame 6  → Focused
Frame 7  → Focused
Frame 8  → Eyes closed
Frame 9  → Focused
Frame 10 → Focused
```

Totals:

```text
Total frames     = 10
Attentive frames = 7
Bad frames       = 3
```

Calculations:

```text
Attention Engagement Rate = 7 / 10 × 100 = 70%
Final Score               = round(70) = 70
Concentration             = 70 / 10 = 7.0/10
Bad Frame Count           = 3
```

If the face was visible in nine frames:

```text
Face Detection = 9 / 10 × 100 = 90%
```

If frames 4 and 5 were one continuous looking-left episode:

```text
Gaze Warning Count = 1
```

The result screen would show approximately:

```text
Score             70%
Performance       Good
Concentration     7.0/10
Face detection    90%
Attention         70%
Frames            10
Metrics           10
```

---

## 7. Local and backend calculation paths

When the local hybrid attention monitor is active, the application calculates the session metrics on the device and sends them to the backend.

In the older WebSocket processing path, some result-screen values are read from the backend's `session_summary`, including:

- Average concentration score
- Face detection rate
- Attention engagement rate
- Maximum inattention duration
- Final attention score
- Frame and stored-metric counts

Therefore, the UI is not independently inventing a second score. It displays either the locally aggregated session metrics or the backend's session summary, depending on which monitoring path handled the session.

---

## Executive summary

The final management score is primarily the percentage of analyzed frames in which the user was classified as focused:

```text
Final Score ≈ Attentive Frames / Total Frames × 100
```

Additional metrics—face visibility, inattention time, gaze quality, lighting, eye closure, blinking, yawning, and head pose—provide context around that score and are sent to the backend for storage and reporting.

