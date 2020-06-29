struct Material{
    vec3 albedo;
    vec3 f0;
    float roughness;
    int kind;
};

struct Light{
    vec3 power;
    vec3 pos;
    vec3 rot;
    int kind;
};

struct Object{
    vec3 pos;
    vec3 rot;
    int kind;
    float[4] params;
    Material material;
};

struct Camera{
    vec3 pos;
    float fov;
    vec3 lookAt;
    vec3 up;
};