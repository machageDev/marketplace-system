from typing import List, Dict, Any
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity


def freelancer_text(profile) -> str:
    
    # Convert skills string → list safely
    skills_list = []
    if profile.skills:
        skills_list = [s.strip() for s in profile.skills.split(",")]

    # Portfolio items (if any)
    portfolio_desc = []
    if hasattr(profile, "portfolio_items"):
        portfolio_desc = [p.description for p in profile.portfolio_items.all()]

    parts = [
        profile.user.name or "",
        profile.bio or "",
        " ".join(skills_list),
        " ".join(portfolio_desc),
    ]

    return " ".join(parts).lower()


def job_text(job) -> str:
    
    tags = job.tags if isinstance(job.tags, list) else []
    req_skills = job.required_skills if isinstance(job.required_skills, list) else []

    parts = [
        job.title or "",
        job.description or "",
        " ".join(tags),
        " ".join(req_skills),
    ]

    return " ".join(parts).lower()


def rank_jobs_for_freelancer(freelancer, jobs, top_n=10):
    from sklearn.feature_extraction.text import TfidfVectorizer
    from sklearn.metrics.pairwise import cosine_similarity

    # Text for freelancer
    freelancer_text_data = " ".join([
        freelancer.bio or "",
        " ".join(freelancer.skills or []),
        freelancer.experience or ""
    ]).lower()

    # Build TF-IDF corpus
    job_texts = [
        (job.id, " ".join([
            job.title or "",
            job.description or "",
            " ".join(job.required_skills or []),
            " ".join(job.tags or [])
        ]).lower())
        for job in jobs
    ]

    corpus = [freelancer_text_data] + [text for _, text in job_texts]

    vectorizer = TfidfVectorizer(stop_words="english", max_features=4000)
    X = vectorizer.fit_transform(corpus)

    freelancer_vec = X[0]
    job_vecs = X[1:]
    sims = cosine_similarity(freelancer_vec, job_vecs).flatten()

    results = []

    for idx, job in enumerate(jobs):
        base = float(sims[idx])

        fr_skills = set([s.lower() for s in (freelancer.skills or [])])
        job_sk = set([s.lower() for s in (job.required_skills or [])])

        skill_overlap = len(fr_skills.intersection(job_sk))
        skill_bonus = min(0.4, 0.1 * skill_overlap)

        score = base + skill_bonus

        results.append({
            "job_id": job.id,
            "score": score,
            "skill_overlap": skill_overlap,
            "base_similarity": base
        })

    return sorted(results, key=lambda r: r["score"], reverse=True)[:top_n]
