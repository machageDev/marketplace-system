from typing import List, Dict, Any
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

# ---------------- Helper functions ----------------
def job_text(job) -> str:
    """Convert a job object into plain text for TF-IDF matching."""
    skills_text = ""
    if hasattr(job, "required_skills") and job.required_skills:
        if isinstance(job.required_skills, str):
            skills_text = " ".join(s.strip() for s in job.required_skills.split(",") if s.strip())
        elif isinstance(job.required_skills, list):
            skills_text = " ".join(str(s).strip() for s in job.required_skills if s)

    return " ".join([
        job.title or "",
        job.description or "",
        skills_text
    ]).lower()


def freelancer_text(freelancer) -> str:
    """Convert a freelancer object into plain text for TF-IDF matching."""
    skills_text = ""
    if freelancer.skills:
        if isinstance(freelancer.skills, str):
            skills_text = " ".join(s.strip() for s in freelancer.skills.split(",") if s.strip())
        elif isinstance(freelancer.skills, list):
            skills_text = " ".join(str(s).strip() for s in freelancer.skills if s)

    return " ".join([
        freelancer.bio or "",
        skills_text,
        freelancer.experience or ""
    ]).lower()


# ---------------- Rank freelancers for a job ----------------
def rank_freelancers_for_job(job, freelancers, top_n=10) -> List[Dict[str, Any]]:
    if not freelancers:
        return []

    # Extract job text
    job_text_data = job_text(job)

    # Build TF-IDF corpus
    freelancer_texts = []
    for freelancer in freelancers:
        freelancer_texts.append(freelancer_text(freelancer))

    corpus = [job_text_data] + freelancer_texts

    # TF-IDF vectorization
    vectorizer = TfidfVectorizer(stop_words="english", max_features=4000)
    X = vectorizer.fit_transform(corpus)

    job_vec = X[0]
    freelancer_vecs = X[1:]
    sims = cosine_similarity(job_vec, freelancer_vecs).flatten()

    results = []
    for idx, freelancer in enumerate(freelancers):
        base_score = float(sims[idx]) * 100  # convert to percentage

        # Skills
        job_skills = set()
        if hasattr(job, 'required_skills') and job.required_skills:
            if isinstance(job.required_skills, str):
                job_skills = {s.strip().lower() for s in job.required_skills.split(",") if s.strip()}
            elif isinstance(job.required_skills, list):
                job_skills = {str(s).strip().lower() for s in job.required_skills if s}

        freelancer_skills = set()
        if freelancer.skills:
            if isinstance(freelancer.skills, str):
                freelancer_skills = {s.strip().lower() for s in freelancer.skills.split(",") if s.strip()}
            elif isinstance(freelancer.skills, list):
                freelancer_skills = {str(s).strip().lower() for s in freelancer.skills if s}

        # Skill overlap bonus
        skill_overlap = len(job_skills.intersection(freelancer_skills))
        skill_bonus = min(30, skill_overlap * 5)  # max 30% bonus

        final_score = min(100, base_score + skill_bonus)

        results.append({
            "profile_id": freelancer.profile_id,
            "score": round(final_score, 2),
            "base_score": round(base_score, 2),
            "skill_overlap": skill_overlap,
            "skill_bonus": skill_bonus,
            "common_skills": list(job_skills.intersection(freelancer_skills)),
        })

    results.sort(key=lambda r: r["score"], reverse=True)
    return results[:top_n]


# ---------------- Rank jobs for a freelancer ----------------
def rank_jobs_for_freelancer(freelancer, jobs, top_n=10) -> List[Dict[str, Any]]:
    # Freelancer text
    freelancer_skills_text = ""
    if freelancer.skills:
        if isinstance(freelancer.skills, str):
            freelancer_skills_text = " ".join([s.strip() for s in freelancer.skills.split(",") if s.strip()])
        elif isinstance(freelancer.skills, list):
            freelancer_skills_text = " ".join([str(s).strip() for s in freelancer.skills if s])

    freelancer_text_data = " ".join([
        freelancer.bio or "",
        freelancer_skills_text,
        freelancer.experience or ""
    ]).lower()

    # Build job texts
    job_texts = []
    job_data = []

    for job in jobs:
        job_skills_text = ""
        if job.required_skills:
            if isinstance(job.required_skills, str):
                job_skills_text = " ".join([s.strip() for s in job.required_skills.split(",") if s.strip()])
            elif isinstance(job.required_skills, list):
                job_skills_text = " ".join([str(s).strip() for s in job.required_skills if s])

        jt = " ".join([job.title or "", job.description or "", job_skills_text]).lower()
        job_texts.append(jt)
        job_data.append({
            "task_id": job.task_id,
            "job": job,
            "skills_text": job_skills_text
        })

    corpus = [freelancer_text_data] + job_texts
    vectorizer = TfidfVectorizer(stop_words="english", max_features=4000)
    X = vectorizer.fit_transform(corpus)

    freelancer_vec = X[0]
    job_vecs = X[1:]
    sims = cosine_similarity(freelancer_vec, job_vecs).flatten()

    results = []
    for idx, jd in enumerate(job_data):
        job = jd["job"]
        base = float(sims[idx])

        fr_skills = set()
        if freelancer.skills:
            if isinstance(freelancer.skills, str):
                fr_skills = {s.strip().lower() for s in freelancer.skills.split(",") if s.strip()}
            elif isinstance(freelancer.skills, list):
                fr_skills = {str(s).strip().lower() for s in freelancer.skills if s}

        job_sk = set()
        if job.required_skills:
            if isinstance(job.required_skills, str):
                job_sk = {s.strip().lower() for s in job.required_skills.split(",") if s.strip()}
            elif isinstance(job.required_skills, list):
                job_sk = {str(s).strip().lower() for s in job.required_skills if s}

        skill_overlap = len(fr_skills.intersection(job_sk))
        skill_bonus = min(0.4, 0.1 * skill_overlap)  # max 40% bonus

        score = base + skill_bonus

        results.append({
            "job_id": job.task_id,
            "score": round(score, 4),
            "skill_overlap": skill_overlap,
            "base_similarity": round(base, 4),
            "skill_bonus": round(skill_bonus, 4),
            "common_skills": list(fr_skills.intersection(job_sk))
        })

    results.sort(key=lambda r: r["score"], reverse=True)
    return results[:top_n]
