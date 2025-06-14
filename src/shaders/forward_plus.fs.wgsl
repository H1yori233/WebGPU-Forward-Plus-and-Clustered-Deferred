// TODO-2: implement the Forward+ fragment shader

// See naive.fs.wgsl for basic fragment shader setup; this shader should use light clusters instead of looping over all lights

// ------------------------------------
// Shading process:
// ------------------------------------
// Determine which cluster contains the current fragment.
// Retrieve the number of lights that affect the current fragment from the cluster’s data.
// Initialize a variable to accumulate the total light contribution for the fragment.
// For each light in the cluster:
//     Access the light's properties using its index.
//     Calculate the contribution of the light based on its position, the fragment’s position, and the surface normal.
//     Add the calculated contribution to the total light accumulation.
// Multiply the fragment’s diffuse color by the accumulated light contribution.
// Return the final color, ensuring that the alpha component is set appropriately (typically to 1).

@group(${bindGroup_scene}) @binding(0) var<uniform> cameraUniforms: CameraUniforms;
@group(${bindGroup_scene}) @binding(1) var<storage, read> lightSet: LightSet;
@group(${bindGroup_scene}) @binding(2) var<storage, read> clusterSet: ClusterSet;

@group(${bindGroup_material}) @binding(0) var diffuseTex: texture_2d<f32>;
@group(${bindGroup_material}) @binding(1) var diffuseTexSampler: sampler;

struct FragmentInput
{
    @builtin(position) fragPos: vec4f,
    @location(0) pos: vec3f,
    @location(1) nor: vec3f,
    @location(2) uv: vec2f
}

fn getClusterIndex(viewPos: vec3f, fragPos: vec4f) -> u32 {
    let tileSizePx = cameraUniforms.screenDimensions.xy / 
                     vec2(${numClustersX}, ${numClustersY});
    let clusterX = clamp(u32(floor(fragPos.x / tileSizePx.x)), 0u, ${numClustersX} - 1u);
    let clusterY = clamp(u32(floor(fragPos.y / tileSizePx.y)), 0u, ${numClustersY} - 1u);

    let clusterZ = getZIndex(-viewPos.z);
    return clusterX + 
           clusterY * ${numClustersX} + 
           clusterZ * ${numClustersX} * ${numClustersY};
}

@fragment
fn main(in: FragmentInput) -> @location(0) vec4f
{
    let diffuseColor = textureSample(diffuseTex, diffuseTexSampler, in.uv);
    if (diffuseColor.a < 0.5f) {
        discard;
    }

    let index = (getClusterIndex(in.pos, in.fragPos));
    let cluster_ptr = &clusterSet.clusters[index];
    
    var totalLightContrib = vec3f(0, 0, 0);
    for (var i = 0u; i < (*cluster_ptr).numLights; i++) {
        let lightIdx = (*cluster_ptr).lightIndices[i];
        let light_ptr = &lightSet.lights[lightIdx];
        totalLightContrib += calculateLightContrib(*light_ptr, in.pos, normalize(in.nor));
    }

    let finalColor = diffuseColor.rgb * totalLightContrib;
    return vec4(finalColor, 1);
}
