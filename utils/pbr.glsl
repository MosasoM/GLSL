float pbr_D(in float roughness,in vec3 n,in vec3 h);
float pbr_V(in float roughness, in vec3 n,in vec3 v,in vec3 l);
vec3 pbr_F(in vec3 f0, in vec3 l,in vec3 h);

float pbr_D(in float roughness,in vec3 n,in vec3 h){
    const float PI = 3.1415926535;
    float al2 = roughness*roughness*roughness*roughness;
    float dotNH2 = dot(n,h)*dot(n,h);
    float base = PI*((dotNH2*(al2-1.0)+1.0)*(dotNH2*(al2-1.0)+1.0));
    return clamp(al2/base,0.0,1.0);
}
float pbr_V(in float roughness, in vec3 n,in vec3 v,in vec3 l){
    float al2 = roughness*roughness*roughness*roughness;
    float dotNL = dot(n,l);
    float dotNV = dot(n,v);

    float base1 = dotNV*sqrt(dotNL*dotNL*(1.0-al2)+al2);
    float base2 = dotNL*sqrt(dotNV*dotNV*(1.0-al2)+al2);

    return clamp(0.5/(base1+base2),0.0,1.0);
}
vec3 pbr_F(in vec3 f0, in vec3 l,in vec3 h){
    float dotLH = dot(l,h);
    float hoge = pow((1.0-dotLH),5.0);

    return clamp(f0+(vec3(1.0)-f0)*hoge,0.0,1.0);
}