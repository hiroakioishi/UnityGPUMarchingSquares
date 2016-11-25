using UnityEngine;
using System.Collections;
using System.Runtime.InteropServices;

public struct VoxelData
{
    public Vector3 position;
    public Vector2 uv;
};

public class GPUMarchingSquares : MonoBehaviour
{
    public RenderTexture DensityTex;

    [SerializeField]
    Shader _renderShader;

    [SerializeField]
    Color _baseColor = Color.blue;
    
    [SerializeField, Range(1, 256)]
    int _gridResolution = 8;

    int _vertexNum = 0;

    [SerializeField, Range(0.0f, 1.0f)]
    float _voxelSize = 1.0f;
    
    ComputeBuffer _voxelBuffer;
    Material _renderMat;

    [SerializeField, Tooltip("補間を行うかどうか")]
    bool _interpolation = true;
    
    void OnEnable()
    {

        _vertexNum = _gridResolution * _gridResolution;

        _voxelBuffer = new ComputeBuffer(_vertexNum, Marshal.SizeOf(typeof(VoxelData)));

        var voxelData = new VoxelData[_vertexNum];
        var voxelSizeX = 1.0f / (1.0f * _gridResolution);
        var voxelSizeY = 1.0f / (1.0f * _gridResolution);
        for (int y = 0, i = 0; y < _gridResolution; y++)
        {
            for (int x = 0; x < _gridResolution; x++, i++)
            {
                voxelData[i].position = Vector3.zero;
                voxelData[i].uv = new Vector2
                (
                    voxelSizeX * x + voxelSizeX * 0.5f,
                    voxelSizeY * y + voxelSizeY * 0.5f
                );
            }
        }
        _voxelBuffer.SetData(voxelData);
        voxelData = null;

        if (_renderMat == null)
        {
            _renderMat = new Material(_renderShader);
            _renderMat.hideFlags = HideFlags.DontSave;
        }

    }

    void Update()
    {

    }

    void OnRenderObject()
    {
        _renderMat.SetPass(0);
        _renderMat.SetTexture("_DensityTex", DensityTex);
        _renderMat.SetColor("_Color", _baseColor);
        _renderMat.SetVector("_VoxelSize", new Vector3(1.0f / _gridResolution, 1.0f / _gridResolution, _voxelSize * 0.5f));
        _renderMat.SetInt("_Interpolation", _interpolation ? 1 : 0);
        _renderMat.SetBuffer("_VoxelBuffer", _voxelBuffer);
        Graphics.DrawProcedural(MeshTopology.Points, _vertexNum);
    }

    void OnDisable()
    {
        if (_voxelBuffer != null)
        {
            _voxelBuffer.Release();
            _voxelBuffer = null;
        }

        if (_renderMat != null)
        {
            DestroyImmediate(_renderMat);
            _renderMat = null;
        }
    }
}