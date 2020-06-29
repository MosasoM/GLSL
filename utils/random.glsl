
//https://www.ci.i.u-tokyo.ac.jp/~hachisuka/tdf2015.pdf
float GPURnd(inout vec4 state)
{
const vec4 q = vec4( 1225.0, 1585.0, 2457.0, 2098.0);
const vec4 r = vec4( 1112.0, 367.0, 92.0, 265.0);
const vec4 a = vec4( 3423.0, 2646.0, 1707.0, 1999.0);
const vec4 m = vec4(4194287.0, 4194277.0, 4194191.0, 4194167.0);
vec4 beta = floor(state / q);
vec4 p = a * (state - beta * q) - beta * r;
beta = (sign(-p) + vec4(1.0)) * vec4(0.5) * m;
state = (p + beta);
return fract(dot(state / m, vec4(1.0, -1.0, 1.0, -1.0)));
}

//famous
float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

//https://www.shadertoy.com/view/XsXfRH
float hash(vec3 p)  // replace this by something better
{
    p  = 50.0*fract( p*0.3183099 + vec3(0.71,0.113,0.419));
    return -1.0+2.0*fract( p.x*p.y*p.z*(p.x+p.y+p.z) );
}