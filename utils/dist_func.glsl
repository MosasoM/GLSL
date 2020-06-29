float sphere_df(in vec3 p,in float r);
float box_df(in vec3 p,in vec3 size);

float sphere_df(in vec3 p,in float r){
    return length(p)-r;
}

float box_df(in vec3 p,in vec3 size){
    vec3 q = abs(p)-size;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}