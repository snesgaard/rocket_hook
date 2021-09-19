local random = {}

random.rand_2d_to_1d = [[

    float rand_2d_to_1d(vec2 value, vec2 dotDir){
        vec2 smallValue = sin(value);
        float random = dot(smallValue, dotDir);
        random = fract(sin(random) * 143758.5453);
        return random;
    }

    float rand_2d_to_1d(vec2 value) {
        return rand_2d_to_1d(value, vec2(12.9898, 78.233));
    }

]]

random.rand_1d_to_1d = [[

    float rand_1d_to_1d(float value, float mutator = 0.546){
    	float random = frac(sin(value + mutator) * 143758.5453);
    	return random;
    }

]]

random.rand_2d_to_2d =
    random.rand_2d_to_1d ..

    [[

    vec2 rand_2d_to_2d(vec2 value){
        return vec2(
            rand_2d_to_1d(value, vec2(12.989, 78.233)),
            rand_2d_to_1d(value, vec2(39.346, 11.135))
        );
    }

]]

random.rand_1d_to_2d =
    random.rand_2d_to_1d ..

    [[

    vec2 rand_1d_to_2d(float value){
        return vec2(
            rand_2d_to_1d(value, 3.9812),
            rand_2d_to_1d(value, 7.1536)
        );
    }

    ]]

return random
