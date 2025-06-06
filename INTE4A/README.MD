# INTE4A

This is an educational tool that performs discrete integration over a domain on the xy-plane. It can be used to check the approximate answers of a problem. It also includes a function to bruteforce integer "answers", if the form of the answer is known.

Requires Processing. Tested on Processing 4.3.

![](image.png)

### Usage Instructions

1. Identify the domain curves and the bounding box, and fill in the appropriate variables. If there is no domain curve, use the matching bounding box variable.
2. Select an appropriate resolution for the discrete integration. Try 1,000 x 1,000 for speed, or 10,000 x 10,000 for accuracy.
3. Choose the values for the color scale. The minimum, middle, and maximum values will be displayed as yellow, red, and blue respectively.
4. Enter your function, which will be used as z = f(x, y).
5. If the form of the answers is known, enter the parameters for bruteforcing. Otherwise, set NumAnswerConstants to 0.
6. Click on the "Run" button.

### Troubleshooting

- **The domain is cut off by the borders of the graph.**
  - The bounding box is too small and does not cover the entire domain. Change the Bounds values.
- **The domain is cut off within the graph by a horizontal or vertical line.**
  - A domain function is set to a constant that is within the bounding box. Change the Domain function.

### Version History

241018 >

- Fixed incorrect first test case used by the form result bruteforcer.

241012 >

- Initial release
