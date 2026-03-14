import numpy as np
import matplotlib.pyplot as plt

def muller_function(n, tail):
    return n**(1 - 1/(2*tail))

if __name__ == "__main__":
    np.random.seed(123)

    #plot the function in Remark 1
    eps = 1e-3
    tail = np.linspace(1 / 3 + eps, 1 / 2 - eps, 100)
    n = np.linspace(50, 10000, 100)

    xi, N = np.meshgrid(tail, n)
    rate = muller_function(N, xi)

    plt.figure(figsize=(8, 6))
    plt.contourf(xi, N, rate, levels=50, cmap="viridis")
    plt.colorbar(label=r"$n^{1 - 1/(2\xi)}$")
    plt.xlabel("Tail index")
    plt.ylabel("Sample size $n$")
    plt.title("CLT size distortion rate (Müller Remark 1)")
    plt.yscale("log")
    plt.show()

    eps = 1e-3
    tail = np.linspace(1 / 3 + eps, 1 / 2 - eps, 200)
    n = 1000

    rate = n ** (1 - 1 / (2 * tail))

    plt.figure(figsize=(7, 5))
    plt.plot(tail, rate)
    plt.xlabel(r"Tail index $\xi$")
    plt.ylabel(r"$n^{1 - 1/(2\xi)}$")
    plt.title(r"CLT size distortion rate (Müller Remark 1), $n=1000$")
    plt.grid(True)
    plt.show()
