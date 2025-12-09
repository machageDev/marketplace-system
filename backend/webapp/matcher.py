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


def rank_freelancers_for_job(job, freelancers, top_n=10) -> List[Dict[str, Any]]:
    """
    Rank freelancers for a specific job based on skills match
    
    Args:
        job: Task object
        freelancers: List of UserProfile objects
        top_n: Number of top matches to return
    
    Returns:
        List of dictionaries with profile_id and match_score
    """
    if not freelancers:
        return []
    
    # Extract job text for matching
    job_text_data = job_text(job)
    
    # Build TF-IDF corpus
    freelancer_texts = []
    freelancer_ids = []
    
    for freelancer in freelancers:
        freelancer_text_data = freelancer_text(freelancer)
        freelancer_texts.append(freelancer_text_data)
        freelancer_ids.append(freelancer.profile_id)
    
    # Combine all texts for vectorization
    corpus = [job_text_data] + freelancer_texts
    
    # Create TF-IDF vectors
    vectorizer = TfidfVectorizer(stop_words="english", max_features=4000)
    X = vectorizer.fit_transform(corpus)
    
    # Get vectors
    job_vec = X[0]  # First vector is the job
    freelancer_vecs = X[1:]  # Rest are freelancers
    
    # Calculate cosine similarity
    sims = cosine_similarity(job_vec, freelancer_vecs).flatten()
    
    results = []
    
    for idx, freelancer in enumerate(freelancers):
        base_score = float(sims[idx]) * 100  # Convert to percentage
        
        # Extract skills for both job and freelancer
        job_skills = set()
        if hasattr(job, 'required_skills') and job.required_skills:
            if isinstance(job.required_skills, str):
                job_skills = {s.strip().lower() for s in job.required_skills.split(",")}
            elif isinstance(job.required_skills, list):
                job_skills = {s.strip().lower() for s in job.required_skills}
        
        freelancer_skills = set()
        if freelancer.skills:
            if isinstance(freelancer.skills, str):
                freelancer_skills = {s.strip().lower() for s in freelancer.skills.split(",")}
            elif isinstance(freelancer.skills, list):
                freelancer_skills = {s.strip().lower() for s in freelancer.skills}
        
        # Calculate skill overlap bonus
        skill_overlap = len(job_skills.intersection(freelancer_skills))
        skill_bonus = min(30, skill_overlap * 5)  # Max 30% bonus
        
        # Category match bonus
        category_bonus = 0
        if hasattr(job, 'category') and hasattr(freelancer, 'category'):
            if job.category and freelancer.category:
                if job.category.lower() == freelancer.category.lower():
                    category_bonus = 20
        
        # Experience bonus
        experience_bonus = 0
        if hasattr(freelancer, 'experience_level'):
            if freelancer.experience_level:
                exp_level = freelancer.experience_level.lower()
                if exp_level == 'expert':
                    experience_bonus = 15
                elif exp_level == 'intermediate':
                    experience_bonus = 10
                elif exp_level == 'beginner':
                    experience_bonus = 5
        
        # Calculate final score
        final_score = base_score + skill_bonus + category_bonus + experience_bonus
        final_score = min(100, final_score)  # Cap at 100%
        
        results.append({
            "profile_id": freelancer.profile_id,
            "score": round(final_score, 2),
            "base_score": round(base_score, 2),
            "skill_overlap": skill_overlap,
            "skill_bonus": skill_bonus,
            "category_bonus": category_bonus,
            "experience_bonus": experience_bonus,
            "common_skills": list(job_skills.intersection(freelancer_skills)),
        })
    
    # Sort by score (descending)
    results.sort(key=lambda r: r["score"], reverse=True)
    
    # Return top N results
    return results[:top_n]


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