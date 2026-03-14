from scipy.stats import genpareto, pareto
from scipy.stats.mstats import winsorize
from scipy import stats
import matplotlib.pyplot as plt
from scipy.stats import t
from scipy import integrate
import os
import numpy as np
from scipy.stats import gaussian_kde
from scipy import integrate


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


def winsor_IF(x, dist, p, sample_lower, sample_upper):
    """
    Per-observation influence function for hat_mu = mean(W_{hat a,hat b}(X_i))
    targeting mu(p)=E[W_{a,b}(X)], where a=Q(p), b=Q(1-p).
    Returns IF_i array, plus (mu,a,b) if you want them.
    """
    x = np.asarray(x, float)
    a = dist.ppf(p)
    b = dist.ppf(1 - p)
    fa = dist.pdf(a)
    fb = dist.pdf(b)

    mu = winsorized_mean(dist, sample_lower, sample_upper)

    # population winsorization of each observation
    W = np.clip(x, a, b)

    Ia = (x <= a).astype(float)
    Ib = (x >  b).astype(float)   # upper tail indicator

    IF = (W - mu) + (p/fa) * (p - Ia) + (p/fb) * (Ib - p)
    return IF, mu, a, b


def adjusted_se_hatmu(x, dist, p, sample_lower, sample_upper):
    IF, mu, a, b = winsor_IF(x, dist, p, sample_lower, sample_upper)
    sdIF = np.std(IF, ddof=1)
    se = sdIF / np.sqrt(len(x))
    return se, mu


class KDE_Dist:
    """
    Drop-in distribution-like object for KDE:
      - pdf(t): kde(t)
      - cdf(t): (optional) approximate via Monte Carlo
      - ppf(q): approximate quantile via KDE resampling
    """
    def __init__(self, x, bw_method="scott", seed=0):
        self.x = np.asarray(x, float)
        self.kde = gaussian_kde(self.x, bw_method=bw_method)
        self.rng = np.random.default_rng(seed)

    def pdf(self, t):
        t = np.asarray(t, float)
        return self.kde(t)

    def ppf(self, q, M=200000):
        """
        Approximate KDE quantile by sampling from the KDE.
        For extreme q (like 0.01), increase M (e.g. 200k–1M).
        """
        q = float(q)
        if not (0.0 < q < 1.0):
            raise ValueError("q must be in (0,1)")
        samp = self.kde.resample(M, seed=self.rng)[0]
        return float(np.quantile(samp, q))

    def cdf(self, t, M=200000):
        """
        Optional: approximate KDE CDF by sampling (same idea).
        """
        t = float(t)
        samp = self.kde.resample(M, seed=self.rng)[0]
        return float(np.mean(samp <= t))


def winsorized_mean_sample(X, p):
    """
    Sample winsorized mean:
      a_hat = Qhat(p), b_hat = Qhat(1-p), W_i = clip(X_i, a_hat, b_hat), return mean(W).
    """
    W = winsorize(X, limits=[p, p])
    return W.mean()


def bootstrap_se_winsorized_mean(x, p=0.01, B=1000, seed=0):
    """
    Nonparametric bootstrap SE for sample winsorized mean.
    """
    rng = np.random.default_rng(seed)
    x = np.asarray(x, float)
    n = len(x)

    thetas = np.empty(B)
    for b in range(B):
        idx = rng.integers(0, n, size=n)   # resample indices w/ replacement
        xb = x[idx]
        thetas[b] = winsorized_mean_sample(xb, p)

    se = thetas.std(ddof=1)
    return se, thetas


if __name__ == "__main__":
    np.random.seed(123)
    alpha = 0.05
    ####################### Pareto Distribution
    pareto_shape = 2.5
    n_rep = 200
    winsorization_percentile = list(range(1, 11))
    sample_size_list = [20, 50, 100, 200, 300, 400, 500, 1000, 2000]

    kde_size_matrix = np.zeros(shape=(len(sample_size_list), len(winsorization_percentile)))
    bootstrap_size_matrix = np.zeros(shape=(len(sample_size_list), len(winsorization_percentile)))
    unwinsorized_size_matrix = np.zeros(shape=(len(sample_size_list), len(winsorization_percentile)))

    for j in range(len(sample_size_list)):
        n = sample_size_list[j]

        for i in range(len(winsorization_percentile)):
            win_p = winsorization_percentile[i]
            p = win_p / 100.0

            kde_reject = np.zeros(n_rep)
            bootstrap_reject = np.zeros(n_rep)
            unwinsorized_reject = np.zeros(n_rep)

            kde_score_temp = []
            unwinsorized_score_temp = []
            bootstrap_score_temp = []

            for r in range(n_rep):
                X = pareto.rvs(b=pareto_shape, size=n)
                dist = pareto(pareto_shape)
                X_win = winsorize(X, limits=[p, p])

                # sample quantile
                a_hat = np.quantile(X, p)
                b_hat = np.quantile(X, 1 - p)

                # population quantile
                a = dist.ppf(p)
                b = dist.ppf(1 - p)
                population_mean = winsorized_mean(dist, lower_value=a, upper_value=b)

                # KDE estimation of the density for the adjusted standard error
                kde_dist = KDE_Dist(X, bw_method="scott")
                kde_adj_se, _ = adjusted_se_hatmu(X, kde_dist, p, a_hat, b_hat)
                kde_score = (np.mean(X_win) - population_mean) / (kde_adj_se)
                kde_score_temp.append(kde_score)
                kde_rej = (abs(kde_score) > 1.96)

                # bootstrapped estimation of the density for the adjusted standard error
                bootsrap_se, _ = bootstrap_se_winsorized_mean(X, p)
                bootstrap_adj_score = (np.mean(X_win) - population_mean) / (bootsrap_se)
                bootstrap_score_temp.append(bootstrap_adj_score)
                bootstrap_rej = (abs(bootstrap_adj_score) > 1.96)

                # Unwinsorized t test
                unwinsorized_population_mean = dist.mean()
                unwinsorized_score = (np.mean(X) - unwinsorized_population_mean) / (np.std(X, ddof=1) / np.sqrt(n))
                unwinsorized_score_temp.append(unwinsorized_score)
                unwinsorized_rej = (abs(unwinsorized_score) > 1.96)

                kde_reject[r] = kde_rej
                bootstrap_reject[r] = bootstrap_rej
                unwinsorized_reject[r] = unwinsorized_rej

            kde_size_matrix[j, i] = np.mean(kde_reject)
            unwinsorized_size_matrix[j, i] = np.mean(unwinsorized_reject)
            bootstrap_size_matrix[j, i] = np.mean(bootstrap_reject)

    out_dir = "non_parametric"  # folder to save into
    os.makedirs(out_dir, exist_ok=True)

    for i in range(len(winsorization_percentile)):
        win_p = winsorization_percentile[i]

        plt.figure(figsize=(10, 10))

        plt.plot(sample_size_list, unwinsorized_size_matrix[:, i], marker="o", label="Unwinsorized")
        plt.plot(sample_size_list, kde_size_matrix[:, i], marker="s", label="kde Winsorized")
        plt.plot(sample_size_list, bootstrap_size_matrix[:, i], marker="s", label="bootstrap Winsorized")
        plt.axhline(alpha, linestyle="--", color="black", label="Nominal α")

        plt.ylabel("Empirical size")
        plt.xlabel("Sample size n")
        plt.title(f"Bootstrap CLT t-test for Pareto({pareto_shape}), p={win_p}%, α={alpha}")

        plt.legend()
        plt.grid(True)
        plt.tight_layout()

        fname_base = f"Bootstrap clt_ttest_Pareto_{pareto_shape}_p{win_p}_alpha{alpha}"
        png_path = os.path.join(out_dir, fname_base + ".png")
        pdf_path = os.path.join(out_dir, fname_base + ".pdf")

        plt.savefig(png_path, dpi=300, bbox_inches="tight")  # raster image
        plt.savefig(pdf_path, bbox_inches="tight")
        # plt.show()  # optional if you still want to display
        # plt.close()       # better than show() if you’re running lots of plots

        ############################### Student T ########################
        np.random.seed(123)
        alpha = 0.05
        df = 2
        n_rep = 200
        winsorization_percentile = list(range(1, 11))

        sample_size_list = [20, 50, 100, 200, 300, 400, 500, 1000, 2000]

        kde_size_matrix = np.zeros(shape=(len(sample_size_list), len(winsorization_percentile)))
        bootstrap_size_matrix = np.zeros(shape=(len(sample_size_list), len(winsorization_percentile)))
        unwinsorized_size_matrix = np.zeros(shape=(len(sample_size_list), len(winsorization_percentile)))

        for j in range(len(sample_size_list)):
            n = sample_size_list[j]

            for i in range(len(winsorization_percentile)):
                win_p = winsorization_percentile[i]
                p = win_p / 100.0

                kde_reject = np.zeros(n_rep)
                bootstrap_reject = np.zeros(n_rep)
                unwinsorized_reject = np.zeros(n_rep)

                kde_score_temp = []
                unwinsorized_score_temp = []
                bootstrap_score_temp = []

                for r in range(n_rep):
                    X = np.random.standard_t(df=df, size=n)
                    dist = t(df = df)
                    X_win = winsorize(X, limits=[p, p])

                    # sample quantile
                    a_hat = np.quantile(X, p)
                    b_hat = np.quantile(X, 1 - p)

                    # population quantile
                    a = dist.ppf(p)
                    b = dist.ppf(1 - p)
                    population_mean = winsorized_mean(dist, lower_value=a, upper_value=b)

                    # density estimation for the adjusted standard error
                    kde_dist = KDE_Dist(X, bw_method="scott")
                    kde_adj_se, _ = adjusted_se_hatmu(X, kde_dist, p, a_hat, b_hat)
                    kde_score = (np.mean(X_win) - population_mean) / (kde_adj_se)
                    kde_score_temp.append(kde_score)
                    kde_rej = (abs(kde_score) > 1.96)

                    # bootstrap estimation for the adjusted standard error
                    bootsrap_se, _ = bootstrap_se_winsorized_mean(X, p)
                    bootstrap_adj_score = (np.mean(X_win) - population_mean) / (bootsrap_se)
                    bootstrap_score_temp.append(bootstrap_adj_score)
                    bootstrap_rej = (abs(bootstrap_adj_score) > 1.96)

                    # unwinsorization t test
                    unwinsorized_population_mean = dist.mean()
                    unwinsorized_score = (np.mean(X) - unwinsorized_population_mean) / (np.std(X, ddof=1) / np.sqrt(n))
                    unwinsorized_score_temp.append(unwinsorized_score)
                    unwinsorized_rej = (abs(unwinsorized_score) > 1.96)

                    kde_reject[r] = kde_rej
                    bootstrap_reject[r] = bootstrap_rej
                    unwinsorized_reject[r] = unwinsorized_rej

                kde_size_matrix[j, i] = np.mean(kde_reject)
                unwinsorized_size_matrix[j, i] = np.mean(unwinsorized_reject)
                bootstrap_size_matrix[j, i] = np.mean(bootstrap_reject)

        out_dir = "non_parametric"  # folder to save into
        os.makedirs(out_dir, exist_ok=True)

        for i in range(len(winsorization_percentile)):
            win_p = winsorization_percentile[i]

            plt.figure(figsize=(10, 10))
            plt.plot(sample_size_list, unwinsorized_size_matrix[:, i], marker="o", label="Unwinsorized")
            plt.plot(sample_size_list, kde_size_matrix[:, i], marker="s", label="kde Winsorized")
            plt.plot(sample_size_list, bootstrap_size_matrix[:, i], marker="s", label="bootstrap Winsorized")
            plt.axhline(alpha, linestyle="--", color="black", label="Nominal α")

            plt.ylabel("Empirical size")
            plt.xlabel("Sample size n")
            plt.title(f"Bootstrap CLT t-test for Student T ({df}), p={win_p}%, α={alpha}")

            plt.legend()
            plt.grid(True)
            plt.tight_layout()

            fname_base = f"Bootstrap clt_ttest_Student_T_{df}_p{win_p}_alpha{alpha}"
            png_path = os.path.join(out_dir, fname_base + ".png")
            pdf_path = os.path.join(out_dir, fname_base + ".pdf")

            plt.savefig(png_path, dpi=300, bbox_inches="tight")  # raster image
            plt.savefig(pdf_path, bbox_inches="tight")
            # plt.show()  # optional if you still want to display
            # plt.close()       # better than show() if you’re running lots of plots
