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


def rank_freelancers_for_job(job, profiles, top_n=10) -> List[Dict[str, Any]]:
   

    # Build TF-IDF corpus
    corpus = [job_text(job)] + [freelancer_text(p) for p in profiles]

    vectorizer = TfidfVectorizer(stop_words='english', max_features=4000)
    X = vectorizer.fit_transform(corpus)

    job_vec = X[0]
    profile_vecs = X[1:]
    sims = cosine_similarity(job_vec, profile_vecs).flatten()

    # Prepare job skills
    job_skills = set([s.lower() for s in (job.required_skills or [])])

    results = []

    for idx, profile in enumerate(profiles):
        base = float(sims[idx])

        # Normalize profile skills
        profile_skill_list = []
        if profile.skills:
            profile_skill_list = [s.strip() for s in profile.skills.split(",")]

        profile_skills = set([s.lower() for s in profile_skill_list])
        skill_overlap = len(job_skills.intersection(profile_skills))
        skill_bonus = min(0.35, 0.1 * skill_overlap)

        # Rating bonus (profile.average_rating() recommended)
        rating = getattr(profile, "rating", 0.0)
        rating_bonus = (rating / 5.0) * 0.3

        # Online bonus if profile has is_online attribute
        activity_bonus = 0.15 if getattr(profile, "is_active_now", False) else 0.0

        # Final score
        score = base + skill_bonus + rating_bonus + activity_bonus

        results.append({
            "profile_id": profile.profile_id,
            "user_id": profile.user.user_id,
            "score": score,
            "base_similarity": base,
            "skill_overlap": skill_overlap,
        })

    return sorted(results, key=lambda r: r["score"], reverse=True)[:top_n]
