package installer

import "testing"

func TestCompareSketchVersions(t *testing.T) {
	cases := []struct {
		a, b string
		want int
	}{
		{"100.4", "99.1", 1},
		{"99.1", "100.4", -1},
		{"100.4", "100.4", 0},
		{"100.4", "100", 1},
		{"100", "100.4", -1},
		{"100.10", "100.9", 1},
		{"100.9", "100.10", -1},
	}
	for _, c := range cases {
		if got := compareSketchVersions(c.a, c.b); got != c.want {
			t.Errorf("compareSketchVersions(%q, %q) = %d, want %d", c.a, c.b, got, c.want)
		}
	}
}
