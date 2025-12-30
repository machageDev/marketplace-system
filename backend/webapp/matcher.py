def rank_freelancers_for_job(job, freelancers, top_n=10) -> List[Dict[str, Any]]:
    """
    Rank freelancers for a specific job based on skills match
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
                job_skills = {s.strip().lower() for s in job.required_skills.split(",") if s.strip()}
            elif isinstance(job.required_skills, list):
                job_skills = {str(s).strip().lower() for s in job.required_skills if s}
        
        freelancer_skills = set()
        if freelancer.skills:
            if isinstance(freelancer.skills, str):
                freelancer_skills = {s.strip().lower() for s in freelancer.skills.split(",") if s.strip()}
            elif isinstance(freelancer.skills, list):
                freelancer_skills = {str(s).strip().lower() for s in freelancer.skills if s}
        
        # Calculate skill overlap bonus
        skill_overlap = len(job_skills.intersection(freelancer_skills))
        skill_bonus = min(30, skill_overlap * 5)  # Max 30% bonus
        
        # REMOVE category match bonus - field doesn't exist
        category_bonus = 0
        
        # REMOVE experience bonus - field doesn't exist
        experience_bonus = 0
        
        # Calculate final score (ONLY base_score + skill_bonus)
        final_score = base_score + skill_bonus  # Removed category_bonus and experience_bonus
        final_score = min(100, final_score)  # Cap at 100%
        
        results.append({
            "profile_id": freelancer.profile_id,
            "score": round(final_score, 2),
            "base_score": round(base_score, 2),
            "skill_overlap": skill_overlap,
            "skill_bonus": skill_bonus,
            # "category_bonus": category_bonus,  # REMOVED
            # "experience_bonus": experience_bonus,  # REMOVED
            "common_skills": list(job_skills.intersection(freelancer_skills)),
        })
    
    # Sort by score (descending)
    results.sort(key=lambda r: r["score"], reverse=True)
    
    # Return top N results
    return results[:top_n]


def rank_jobs_for_freelancer(freelancer, jobs, top_n=10):
    from sklearn.feature_extraction.text import TfidfVectorizer
    from sklearn.metrics.pairwise import cosine_similarity

    # Text for freelancer - handle string skills
    freelancer_skills_text = ""
    if freelancer.skills:
        # Convert comma-separated string to list
        if isinstance(freelancer.skills, str):
            skills_list = [s.strip() for s in freelancer.skills.split(",") if s.strip()]
            freelancer_skills_text = " ".join(skills_list)
        elif isinstance(freelancer.skills, list):
            freelancer_skills_text = " ".join([str(s).strip() for s in freelancer.skills if s])
    
    freelancer_text_data = " ".join([
        freelancer.bio or "",
        freelancer_skills_text,
        freelancer.experience or ""
    ]).lower()
    
    # Build TF-IDF corpus for jobs
    job_texts = []
    job_data = []
    
    for job in jobs:
        # Convert job skills from string to text
        job_skills_text = ""
        if job.required_skills:
            if isinstance(job.required_skills, str):
                skills_list = [s.strip() for s in job.required_skills.split(",") if s.strip()]
                job_skills_text = " ".join(skills_list)
            elif isinstance(job.required_skills, list):
                job_skills_text = " ".join([str(s).strip() for s in job.required_skills if s])
        
        job_text = " ".join([
            job.title or "",
            job.description or "",
            job_skills_text,
        ]).lower()
        
        job_texts.append(job_text)
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
    
    for idx, job_info in enumerate(job_data):
        job = job_info["job"]
        base = float(sims[idx])
        
        # Get freelancer skills as set
        fr_skills = set()
        if freelancer.skills:
            if isinstance(freelancer.skills, str):
                fr_skills = {s.strip().lower() for s in freelancer.skills.split(",") if s.strip()}
            elif isinstance(freelancer.skills, list):
                fr_skills = {str(s).strip().lower() for s in freelancer.skills if s}
        
        # Get job skills as set
        job_sk = set()
        if job.required_skills:
            if isinstance(job.required_skills, str):
                job_sk = {s.strip().lower() for s in job.required_skills.split(",") if s.strip()}
            elif isinstance(job.required_skills, list):
                job_sk = {str(s).strip().lower() for s in job.required_skills if s}
        
        # Calculate skill overlap
        skill_overlap = len(fr_skills.intersection(job_sk))
        skill_bonus = min(0.4, 0.1 * skill_overlap)  # Max 40% bonus for skills
        
        # REMOVE category match bonus - field doesn't exist
        # category_bonus = 0
        # if hasattr(job, 'category') and hasattr(freelancer, 'category'):
        #     if job.category and freelancer.category:
        #         if job.category.lower() == freelancer.category.lower():
        #             category_bonus = 0.3
        
        score = base + skill_bonus  # Removed: + category_bonus
        
        results.append({
            "job_id": job.task_id,
            "score": score,
            "skill_overlap": skill_overlap,
            "base_similarity": base,
            "skill_bonus": skill_bonus,
            # "category_bonus": category_bonus,  # REMOVED
            "common_skills": list(fr_skills.intersection(job_sk))
        })
    
    # Sort by score (descending) and return top N
    results.sort(key=lambda r: r["score"], reverse=True)
    return results[:top_n]