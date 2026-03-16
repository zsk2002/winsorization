import numpy as np
from typing import Tuple
from scipy.stats import genpareto, pareto
from scipy.stats.mstats import winsorize
from scipy import stats
import matplotlib.pyplot as plt
from scipy.stats import t
from scipy import integrate
import os


def winsorized_mean(dist, lower_value, upper_value):
    """
    Population winsorized mean of X ~ dist, winsorizing p in each tail.
    dist must have .ppf, .cdf, .pdf.
    p in [0, 0.5).
    """
    Fa = dist.cdf(lower_value)  # ~ p
    Fb = dist.cdf(upper_value)  # ~ 1-p
    mid, _ = integrate.quad(lambda x: x * dist.pdf(x), lower_value, upper_value, limit=200)

    return lower_value * Fa + mid + upper_value * (1 - Fb)


if __name__ == "__main__":
    np.random.seed(123)
    ################################### pareto distribution
    alpha = 0.05
    pareto_shape = 2.5 # using pareto distribution
    n_rep = 1000
    winsorization_percentile = list(range(1, 11))
    sample_size_list = [20, 50, 100, 200, 300, 400, 500, 1000, 2000]
    size_matrix = np.zeros(shape=(len(sample_size_list), len(winsorization_percentile)))
    unwinsorized_size_matrix = np.zeros(shape=(len(sample_size_list), len(winsorization_percentile)))

    for j in range(len(sample_size_list)):
        n = sample_size_list[j]

        for i in range(len(winsorization_percentile)):
            win_p = winsorization_percentile[i]
            p = win_p / 100.0
            reject = np.zeros(n_rep)
            unwinsorized_reject = np.zeros(n_rep)

            score_temp = []
            unwinsorized_score_temp = []

            for r in range(n_rep):
                X = pareto.rvs(b=pareto_shape, size=n)
                dist = pareto(pareto_shape)
                X_win = winsorize(X, limits=[p, p])

                # sample quantile
                a_hat = np.quantile(X, p)
                b_hat = np.quantile(X, 1 - p)

                true_mean = winsorized_mean(dist, lower_value = a_hat, upper_value = b_hat)
                score = (np.mean(X_win) - true_mean) / (np.std(X_win) / np.sqrt(n))
                score_temp.append(score)

                unwinsorized_population_mean = dist.mean()
                unwinsorized_score = (np.mean(X) - unwinsorized_population_mean) / (np.std(X, ddof=1) / np.sqrt(n))
                unwinsorized_score_temp.append(unwinsorized_score)

                rej = (abs(score) > 1.96)
                unwinsorized_rej = (abs(unwinsorized_score) > 1.96)

                reject[r] = rej
                unwinsorized_reject[r] = unwinsorized_rej

            size_matrix[j, i] = np.mean(reject)
            unwinsorized_size_matrix[j, i] = np.mean(unwinsorized_reject)

    out_dir = "population_mean_sample_quantile"  # folder to save into
    os.makedirs(out_dir, exist_ok=True)

    for i in range(len(winsorization_percentile)):
        win_p = winsorization_percentile[i]

        plt.figure(figsize=(10, 10))

        plt.plot(sample_size_list, unwinsorized_size_matrix[:, i], marker="o", label="Unwinsorized")
        plt.plot(sample_size_list, size_matrix[:, i], marker="s", label="Winsorized")
        plt.axhline(alpha, linestyle="--", color="black", label="Nominal α")

        plt.ylabel("Empirical size")
        plt.xlabel("Sample size n")
        plt.title(f"CLT t-test for Pareto({pareto_shape}), p={win_p}%, α={alpha}")

        plt.legend()
        plt.grid(True)
        plt.tight_layout()

        fname = f"clt_ttest_Pareto {pareto_shape}_p{win_p}_alpha{alpha}.png"
        path = os.path.join(out_dir, fname)
        plt.savefig(path, dpi=300, bbox_inches="tight")

        fname_base = f"clt_ttest_Pareto {pareto_shape}_p{win_p}_alpha{alpha}"
        png_path = os.path.join(out_dir, fname_base + ".png")
        pdf_path = os.path.join(out_dir, fname_base + ".pdf")

        plt.savefig(png_path, dpi=300, bbox_inches="tight")
        plt.savefig(pdf_path, bbox_inches="tight")
        # plt.show()
        # plt.close()


        # # student t
        alpha = 0.05
        df = 2 # using t distribution
        n_rep = 1000
        winsorization_percentile = list(range(1, 11))
        sample_size_list = [20, 50, 100, 200, 300, 400, 500, 1000, 2000]
        size_matrix = np.zeros(shape=(len(sample_size_list), len(winsorization_percentile)))
        unwinsorized_size_matrix = np.zeros(shape=(len(sample_size_list), len(winsorization_percentile)))

        for j in range(len(sample_size_list)):
            n = sample_size_list[j]
            for i in range(len(winsorization_percentile)):
                win_p = winsorization_percentile[i]
                p = win_p / 100.0
                reject = np.zeros(n_rep)
                unwinsorized_reject = np.zeros(n_rep)
                score_temp = []
                unwinsorized_score_temp = []

                for r in range(n_rep):
                    X = np.random.standard_t(df=df, size=n)
                    dist = t(df = df)
                    X_win = winsorize(X, limits=[p, p])

                    # sample quantile
                    a_hat = np.quantile(X, p)
                    b_hat = np.quantile(X, 1 - p)

                    # population mean winsoirzed at the sample quantile
                    true_mean = winsorized_mean(dist, lower_value=a_hat, upper_value=b_hat)
                    score = (np.mean(X_win) - true_mean) / (np.std(X_win) / np.sqrt(n))
                    score_temp.append(score)
                    unwinsorized_population_mean = dist.mean()
                    unwinsorized_score = (np.mean(X) - unwinsorized_population_mean) / (np.std(X, ddof=1) / np.sqrt(n))
                    unwinsorized_score_temp.append(unwinsorized_score)

                    rej = (abs(score) > 1.96)
                    unwinsorized_rej = (abs(unwinsorized_score) > 1.96)

                    reject[r] = rej
                    unwinsorized_reject[r] = unwinsorized_rej

                size_matrix[j, i] = np.mean(reject)
                unwinsorized_size_matrix[j, i] = np.mean(unwinsorized_reject)

        out_dir = "population_mean_sample_quantile"  # folder to save into
        os.makedirs(out_dir, exist_ok=True)

        for i in range(len(winsorization_percentile)):
            win_p = winsorization_percentile[i]

            plt.figure(figsize=(10, 10))

            plt.population_mean_sample_quantile(sample_size_list, unwinsorized_size_matrix[:, i], marker="o", label="Unwinsorized")
            plt.population_mean_sample_quantile(sample_size_list, size_matrix[:, i], marker="s", label="Winsorized")
            plt.axhline(alpha, linestyle="--", color="black", label="Nominal α")

            plt.ylabel("Empirical size")
            plt.xlabel("Sample size n")
            plt.title(f"CLT t-test for Student_T ({df}), p={win_p}%, α={alpha}")

            plt.legend()
            plt.grid(True)
            plt.tight_layout()

            fname = f"clt_ttest_Student_T {df}_p{win_p}_alpha{alpha}.png"
            path = os.path.join(out_dir, fname)
            plt.savefig(path, dpi=300, bbox_inches="tight")

            fname_base = f"clt_ttest_Student_T {df}_p{win_p}_alpha{alpha}"
            png_path = os.path.join(out_dir, fname_base + ".png")
            pdf_path = os.path.join(out_dir, fname_base + ".pdf")

            plt.savefig(png_path, dpi=300, bbox_inches="tight")
            plt.savefig(pdf_path, bbox_inches="tight")
            plt.show()
            plt.close()