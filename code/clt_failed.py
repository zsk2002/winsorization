import numpy as np
from scipy.stats import genpareto, pareto
import matplotlib.pyplot as plt
from scipy.stats import t
from scipy import integrate

 # comment out is for t distribution
if __name__ == "__main__":
    np.random.seed(123)
    alpha = 0.05
    n = np.concatenate([
        np.arange(10, 40, 10),
        np.arange(50, 1001, 100),
        np.arange(2000, 10001, 1000)
    ])
    n_rep = 10000
    emp_size = np.zeros(len(n))
    pareto_shape = 1.2
    # df = 2.5
    for i, curr_sample_size in enumerate(n):
        reject = np.zeros(n_rep, dtype=bool)

        for r in range(n_rep):
            # x = np.random.standard_t(df=df, size=curr_sample_size)
            # if (curr_sample_size < 50):
            #     print(np.mean(x))
            x = pareto.rvs(b = pareto_shape,  size = curr_sample_size)
            #

            true_mean = pareto.mean(b = pareto_shape)
            # true_mean = 0
            t_stat = (np.mean(x) - true_mean) / (np.std(x) / np.sqrt(curr_sample_size))
            # tt = stats.ttest_1samp(x, popmean=0.0)
            reject[r] = (abs(t_stat) > 1.96)
            # reject[r] = (tt.pvalue < alpha)

        emp_size[i] = reject.mean()
        print(f"n={curr_sample_size:5d}  size={emp_size[i]:.4f}")

    # # plot
    plt.figure(figsize=(7, 5))
    plt.plot(n, emp_size, marker="o")
    plt.axhline(alpha, linestyle="--", color="black")
    plt.ylim(0, 0.7)
    plt.xlabel("Sample size n")
    plt.ylabel(f"Empirical size (alpha = {alpha:.2f})")
    plt.title(f"CLT-based t-test size under heavy tails (pareto shape= {pareto_shape})")
    plt.grid(True, which="both")
    plt.show()