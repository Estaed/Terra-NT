double clampOffset(double offset) => offset.clamp(-76.0, 0.0).toDouble();

bool isOpenAfterRelease(double offset) => offset < -38;

bool didMove(double delta) => delta.abs() > 4;
