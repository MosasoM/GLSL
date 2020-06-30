//バリューノイズは基本的にブロックぽくなるのであんまり良くないかもね。

//2Dvalue noise

float vNoise2D(in vec2 x){
    vec2 p = floor(x);
    vec2 w = fract(x);

    vec2 u = w*w*w*(w*(w*6.0-15.0)+10.0);

    float a = RandomFunc(p+vec2(0.0,0.0));
    float b = RandomFunc(p+vec2(1.0,0.0));
    float c = RandomFunc(p+vec2(1.0,1.0));
    float d = RandomFunc(p+vec2(0.0,1.0));

    float k1 = b-a;
    float k2 = d-a;
    float k3 = a-b+c-d;

    return a+k1*u.x+k2*u.y+k3*u.x*u.y;

}

//2D value noise derivative
vec2 vNoise2D_deriv(in vec2 x){
    vec2 p = floor(x);
    vec2 w = fract(x);

    vec2 u = w*w*w*(w*(w*6.0-15.0)+10.0);
    vec2 du = 30.0*w*w*(w*(w-2.0)+1.0);

    float k1 = b-a;
    float k2 = d-a;
    float k3 = a-b+c-d;

    return vec2((k1+k3*u.y)*du.x,(k2+k3*u.x)*du.y);
}