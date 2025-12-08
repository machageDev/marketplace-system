from typing import List, Dict, Any
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

def freelancer_text(freelancer) -> str:
    parts = [
        freelancer.user.get_full_name() or "",
        freelancer.bio or "",
        " ".join(freelancer.skills or []),
        " ".join([p.description for p in getattr(freelancer, "portfolio_items", [])]),
    ]
    return " ".join(parts).lower()

def job_text(job) -> str:
    parts = [
        job.title or "",
        job.description or "",
        " ".join(job.tags or []),
        " ".join(job.required_skills or []),
    ]
    return " ".join(parts).lower()

def rank_freelancers_for_job(job, freelancers, top_n=10) -> List[Dict[str, Any]]:
    corpus = [job_text(job)] + [freelancer_text(f) for f in freelancers]

    vectorizer = TfidfVectorizer(stop_words='english', max_features=4000)
    X = vectorizer.fit_transform(corpus)

    job_vec = X[0]
    fr_vecs = X[1:]
    sims = cosine_similarity(job_vec, fr_vecs).flatten()

    job_skills = set([s.lower() for s in (job.required_skills or [])])

    results = []
    for idx, f in enumerate(freelancers):
        base = float(sims[idx])

        fr_skills = set([s.lower() for s in (f.skills or [])])
        skill_overlap = len(job_skills.intersection(fr_skills))
        skill_bonus = min(0.35, 0.1 * skill_overlap)

        rating_bonus = (getattr(f, 'rating', 0.0) / 5.0) * 0.3
        activity_bonus = 0.15 if getattr(f, 'is_online', False) else 0.0

        score = base + skill_bonus + rating_bonus + activity_bonus

        results.append({
            'freelancer_id': f.id,
            'score': score,
            'base_similarity': base,
            'skill_overlap': skill_overlap,
        })

    return sorted(results, key=lambda r: r['score'], reverse=True)[:top_n]
