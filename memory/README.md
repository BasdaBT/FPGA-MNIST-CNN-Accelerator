# Memory initialization files

The RTL expects the following hexadecimal text files through `$readmemh`. One value is expected per line unless the exporter uses another `$readmemh`-compatible whitespace format.

| Filename | Elements | Stored width | Contents |
| --- | ---: | ---: | --- |
| `test_image_8_label_5_hex.txt` | 784 | 8-bit unsigned | 28×28 input image |
| `conv1_weights_hex.txt` | 36 | 8-bit signed | 3×3×1×4 convolution weights |
| `conv1_bias_hex.txt` | 4 | 16-bit signed | Convolution biases |
| `dense1_weights_hex.txt` | 21,632 | 8-bit signed | 676×32 dense weights, input-major order |
| `dense1_bias_hex.txt` | 32 | 8-bit signed | First dense-layer biases |
| `dense2_weights_hex.txt` | 1,024 | 8-bit signed | 32×32 dense weights, input-major order |
| `dense2_bias_hex.txt` | 32 | 8-bit signed | Second dense-layer biases |
| `output_weights_hex.txt` | 320 | 8-bit signed | 32×10 output weights, input-major order |
| `output_bias_hex.txt` | 10 | 8-bit signed | Output-layer biases |

Signed values must be encoded in two's-complement hexadecimal. Keep these basenames unchanged unless the matching `$readmemh` calls in `rtl/` are updated.

These data files were not present in the supplied project bundle. This manifest documents the reproducibility gap instead of substituting placeholder model parameters.
