# Notes

## Multi-axis timing

Investigate the potential of using the __CSS Properties and Values API__ to enable multi-axis transform timing:

```css
@property --sx {
  syntax: "<number>";
  inherits: false;
  initial-value: 1;
}

.box {
  transform: scaleX(var(--sx));
  transition: --sx 300ms ease;
}

.box:hover {
  --sx: 1.4;
}

transition:
  --sx 200ms ease-out,
  --sy 600ms ease-in,
  --sz 400ms linear;
```
